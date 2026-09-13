import { GameAudio } from './audio.js';

export class MoonAudio extends GameAudio {
  constructor(){super();this.music={stop(){}};this.ambientKey=null;this.ambientToken=0;}
  async load(){await super.load();const r=await fetch('moon/audio/manifest.json');if(!r.ok)throw new Error('Missing Moon audio. Run build:moon.');Object.assign(this.manifest,await r.json());}
  cue(path,volume=1){this.play('moon/evt/zombie_moon/'+path,volume);}
  weapon(kind,def){
    const special=def.id==='microwavegun_zm'?'moon/wpn/microwave/rifle/plr/microwave_rifle_shot':def.id==='microwavegundw_zm'?'moon/wpn/microwave/dw/plr/microwave_shot':null;
    if(kind==='shot'&&special){this.play(special,.8);return;}
    if(kind==='shot'){
      const alias=def.sounds?.fireSound??def.sounds?.fireSoundPlayer,name=alias?.replace(/_plr$/,'');
      const native=name&&Object.keys(this.manifest).find(k=>k.endsWith('/'+name)||k.endsWith('/'+name+'_00'));
      if(native){this.play(native,.8);return;}
      const base=def.id.replace(/_zm$/,'').replace(/_acog|_lps|dw/g,'');
      const found=Object.keys(this.manifest).find(k=>k.startsWith('moon/wpn/')&&k.includes('/'+base+'/')&&k.includes('/plr/shot/'));
      if(found){this.play(found,.8);return;}
    }
    super.weapon(kind,def);
  }
  environment(env){
    if(!this.ctx)return;
    const key=env.lunar?(env.breathable?env.zone==='forest_zone'?'moon/evt/zombie_moon/amb/biodome_bg_l':/tower|forest_east/.test(env.zone??'')?'moon/evt/zombie_moon/amb/lab_bg_l':'moon/evt/zombie_moon/amb/airlock_bg_l':'moon/mus/zombie/moon/underscore_l'):null;
    if(key===this.ambientKey)return;this.ambientKey=key;const token=++this.ambientToken;this.ambient?.stop();this.ambient=null;
    if(key)this.native(key,.13,true).then(source=>{if(token!==this.ambientToken)source.stop();else this.ambient=source;}).catch(console.error);
  }
  reset(){this.musicToken++;this.music?.stop();this.music={stop(){}};this.ambientToken++;this.ambient?.stop();this.ambient=null;this.ambientKey=null;}
}
