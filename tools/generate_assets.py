#!/usr/bin/env python3
"""Generate original source atlas, real KTX1 mip chain, and prototype WAV audio."""
from pathlib import Path
import math, random, shutil, struct, subprocess, wave
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
TEX=ROOT/"assets"/"textures"; AUDIO=ROOT/"assets"/"audio"
TEX.mkdir(parents=True,exist_ok=True); AUDIO.mkdir(parents=True,exist_ok=True)
random.seed(24)

def make_atlas():
    tile=256; atlas=Image.new("RGBA",(512,512),(0,0,0,255))
    asphalt=Image.new("RGBA",(tile,tile)); p=asphalt.load()
    for y in range(tile):
        for x in range(tile):
            n=random.randint(-14,14); p[x,y]=(54+n,61+n,72+n,255)
    facade=Image.new("RGBA",(tile,tile),(87,100,119,255)); d=ImageDraw.Draw(facade)
    for r in range(5):
        for c in range(4):
            x,y=13+c*61,14+r*48
            d.rectangle((x,y,x+39,y+29),fill=(18,38,57,255),outline=(149,157,166,255),width=3)
    grass=Image.new("RGBA",(tile,tile)); p=grass.load()
    for y in range(tile):
        for x in range(tile):
            n=random.randint(-18,18); p[x,y]=(34+n,78+n*2,47+n,255)
    concrete=Image.new("RGBA",(tile,tile),(119,126,135,255)); d=ImageDraw.Draw(concrete)
    for y in range(0,tile,32): d.line((0,y,tile,y),fill=(85,94,105,255),width=2)
    for x in range(0,tile,32): d.line((x,0,x,tile),fill=(91,99,111,255),width=2)
    atlas.paste(asphalt,(0,0)); atlas.paste(facade,(256,0)); atlas.paste(grass,(0,256)); atlas.paste(concrete,(256,256))
    return atlas

def write_ktx(image,path):
    magic=b"\xABKTX 11\xBB\r\n\x1A\n"
    header=struct.pack("<13I",0x04030201,0x1401,1,0x1908,0x8058,0x1908,512,512,0,0,1,10,0)
    out=bytearray(magic+header); mip=image
    for level in range(10):
        data=mip.tobytes(); out.extend(struct.pack("<I",len(data))); out.extend(data)
        while len(out)%4: out.append(0)
        if level<9: mip=mip.resize((max(1,mip.width//2),max(1,mip.height//2)),Image.Resampling.BOX)
    path.write_bytes(out)

def write_audio():
    rate=22050; count=int(rate*2.5); samples=[]
    for i in range(count):
        t=i/rate; mod=.5+.5*math.sin(2*math.pi*.33*t); f=46+12*mod
        val=.42*math.sin(2*math.pi*f*t)+.2*math.sin(4*math.pi*f*t)+.09*math.sin(6*math.pi*f*t)
        fade=min(1.0,i/(rate*.08),(count-i)/(rate*.08))
        samples.append(int(max(-1,min(1,val*fade))*32767))
    with wave.open(str(AUDIO/"engine_loop.wav"),"wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(rate); w.writeframes(struct.pack("<"+"h"*len(samples),*samples))
    line="You copy? The city grid is flickering again. Hit the three signal gates, then take the south road out. Keep your speed steady. I'll talk you through it."
    voice=shutil.which("espeak-ng") or shutil.which("espeak")
    if voice: subprocess.run([voice,"-v","en-us+f3","-s","148","-p","43","-a","170","-w",str(AUDIO/"dispatcher_first_light.wav"),line],check=True)
    else:
        with wave.open(str(AUDIO/"dispatcher_first_light.wav"),"wb") as w:
            w.setnchannels(1); w.setsampwidth(2); w.setframerate(rate); w.writeframes(b"\x00\x00"*rate)

def main():
    image=make_atlas(); image.save(TEX/"afterlight_atlas.png"); write_ktx(image,TEX/"afterlight_atlas.ktx"); write_audio()
    print("Generated 512x512 source atlas, genuine KTX1 10-level mip chain, and WAV assets.")

if __name__=="__main__": main()
