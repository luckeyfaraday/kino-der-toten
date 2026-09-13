import * as THREE from 'three';
import { PlayerController } from './player-controller.js';

// Keep Kino's movement and capsule solver. Coast's sloped terrain also needs
// the small gap between a sphere's lowest point and its tangent plane included
// in the grounding probe; a flat-floor probe flickers between air and ground.
export class CoastController extends PlayerController {
  _probeGround() {
    if (!this.worldReady || !this.worldOctree.rayIntersect) return false;
    this._coastRay ??= new THREE.Ray(new THREE.Vector3(), new THREE.Vector3(0, -1, 0));
    this._coastNormal ??= new THREE.Vector3();
    this._coastRay.origin.copy(this.feetPosition).y += this.groundProbeDistance;
    const hit = this.worldOctree.rayIntersect(this._coastRay);
    if (!hit) return false;
    hit.triangle.getNormal(this._coastNormal);
    if (this._coastNormal.y < this.floorNormalY) return false;
    const tangentGap = this.radius * (1/this._coastNormal.y - 1);
    if (hit.distance > this.groundProbeDistance + tangentGap + this.skin*2) return false;
    this._collisionNormal.copy(this._coastNormal);
    return true;
  }
}
