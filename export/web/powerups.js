import * as THREE from 'three';
import { loadModel } from './animation.js';
import { POWERUP_LIFETIME, powerupVisible } from './rules.js';

// Native pickup meshes with a browser rendition of fx_zombie_powerup_on/grab.
export class Powerups {
  constructor(scene,data,audio,onCollect){Object.assign(this,{scene,data,audio,onCollect});this.items=[];this.bursts=[];this.templates={};
    const size=64,pixels=new Uint8Array(size*size*4);
    for(let y=0;y<size;y++)for(let x=0;x<size;x++){const i=(y*size+x)*4,r=Math.hypot(x-31.5,y-31.5)/31.5;pixels.set([180,255,105,Math.round(255*Math.pow(Math.max(0,1-r),2.5))],i);}
    this.texture=new THREE.DataTexture(pixels,size,size);this.texture.needsUpdate=true;
    this.spriteMaterial=new THREE.SpriteMaterial({map:this.texture,color:0x43ee0c,transparent:true,opacity:.6,blending:THREE.AdditiveBlending,depthWrite:false,toneMapped:false});
  }
  async load(){await Promise.all(Object.entries(this.data.powerups).map(async([type,def])=>{
    const model=await loadModel(def.model);model.traverse(o=>{if(!o.isMesh)return;o.frustumCulled=false;
      const tune=m=>{const c=m.clone();c.color.setHex(0x9e761d);c.emissive.setHex(0x362305);c.emissiveIntensity=.35;c.roughness=.38;return c;};o.material=Array.isArray(o.material)?o.material.map(tune):tune(o.material);
    });this.templates[type]=model;
  }));}
  spawn(type,position){
    if(!this.templates[type])return null;
    const root=new THREE.Group(),model=this.templates[type].clone(true),aura=new THREE.Sprite(this.spriteMaterial);aura.scale.set(94,94,1);root.add(aura,model);
    const motes=[];for(let i=0;i<9;i++){const p=new THREE.Sprite(this.spriteMaterial);p.scale.setScalar(10);root.add(p);motes.push(p);}
    root.position.copy(position).y+=40;this.scene.add(root);
    const item={type,root,model,aura,motes,age:0,from:new THREE.Quaternion(),to:new THREE.Quaternion(),turn:0,duration:0};this.items.push(item);
    this.audio.event('powerup/spawn/spawn_00',.65);return item;
  }
  burst(position){const sprite=new THREE.Sprite(this.spriteMaterial.clone());sprite.position.copy(position);this.scene.add(sprite);this.bursts.push({sprite,age:0});}
  update(dt,feet,canCollect=true,lineClear=()=>true){
    for(const p of [...this.items]){
      p.age+=dt;p.turn+=dt;
      if(p.turn>=p.duration){p.from.copy(p.model.quaternion);p.to.setFromEuler(new THREE.Euler((Math.random()-.5)*2.1,Math.random()*Math.PI*2,(Math.random()-.5)*1.57));p.duration=2.5+Math.random()*2.5;p.turn=0;}
      const t=p.turn/p.duration;p.model.quaternion.slerpQuaternions(p.from,p.to,t*t*(3-2*t));p.model.visible=powerupVisible(p.age);
      p.aura.scale.setScalar(88+Math.sin(p.age*3)*7);
      p.motes.forEach((m,i)=>{const a=p.age*1.4+i*2.4;m.position.set(Math.cos(a)*(16+i%3*4),((p.age*24+i*7)%65)-30,Math.sin(a)*(16+i%3*4));});
      if(p.age>=POWERUP_LIFETIME){this.remove(p);continue;}
      if(canCollect&&feet.distanceTo(p.root.position)<64&&lineClear(feet.clone().add(new THREE.Vector3(0,40,0)),p.root.position)){
        const position=p.root.position.clone();this.remove(p);this.burst(position);this.onCollect(p.type,position);
      }
    }
    for(const b of [...this.bursts]){b.age+=dt;b.sprite.scale.setScalar(30+b.age*240);b.sprite.material.opacity=Math.max(0,1-b.age*1.8);if(b.age>.6){b.sprite.removeFromParent();b.sprite.material.dispose();this.bursts.splice(this.bursts.indexOf(b),1);}}
  }
  remove(p){p.root.removeFromParent();this.items.splice(this.items.indexOf(p),1);}
  reset(){for(const p of [...this.items])this.remove(p);for(const b of this.bursts){b.sprite.removeFromParent();b.sprite.material.dispose();}this.bursts=[];}
  snapshot(){return this.items.map(p=>({type:p.type,model:this.data.powerups[p.type].model,position:p.root.position.toArray(),age:p.age,life:POWERUP_LIFETIME-p.age,visible:p.model.visible}));}
}
