/* 
 * Copyright (c) 2025 SingChun LEE @ Bucknell University. CC BY-NC 4.0.
 * 
 * This code is provided mainly for educational purposes at Bucknell University.
 *
 * This code is licensed under the Creative Commons Attribution-NonCommerical 4.0
 * International License. To view a copy of the license, visit 
 *   https://creativecommons.org/licenses/by-nc/4.0/
 * or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
 *
 * You are free to:
 *  - Share: copy and redistribute the material in any medium or format.
 *  - Adapt: remix, transform, and build upon the material.
 *
 * Under the following terms:
 *  - Attribution: You must give appropriate credit, provide a link to the license,
 *                 and indicate if changes where made.
 *  - NonCommerical: You may not use the material for commerical purposes.
 *  - No additional restrictions: You may not apply legal terms or technological 
 *                                measures that legally restrict others from doing
 *                                anything the license permits.
 */

// TODO 3: Define a struct to store a particle
struct Particle {
  position: vec2f,
  initial_position: vec2f,
  velocity: vec2f,
  initial_velocity: vec2f,
  lifespan: vec2f,
}

// TODO 4: Write the bind group spells here using array<Particle>
// name the binded variables particlesIn and particlesOut

@group(0) @binding(0) var<storage> particlesIn: array<Particle>;
@group(0) @binding(1) var<storage, read_write> particlesOut: array<Particle>;

struct VertexOut {
  @builtin(position)pos: vec4f,
  @location(0) ypos: f32
}

@vertex
fn vertexMain(@builtin(instance_index) idx: u32, @builtin(vertex_index) vIdx: u32) -> VertexOut {
  // TODO 5: Revise the vertex shader to draw circle to visualize the particles
  let particle = particlesIn[idx].position;
  let size = 0.0125 * -1.0/(pow(127.5,2)) * particlesIn[idx].lifespan.x * (particlesIn[idx].lifespan.x - 255);
  let pi = 3.14159265;
  let theta = 2. * pi / 8 * f32(vIdx);
  //let x = cos(theta) * size;
  //let y = sin(theta) * size;
  var x : f32;
  var y : f32;
  switch(vIdx) {
    case 0:
    {x = -3. * size * cos(2. * pi * f32(particlesIn[idx].lifespan.x)/255.);
    y = 3. * size * sin(2. * pi * f32(particlesIn[idx].lifespan.x)/255.);
    break;}
    case 1:
    {x = -3. * size * cos(2. * pi * f32(particlesIn[idx].lifespan.x)/255.);
    y = -3. * size * sin(2. * pi * f32(particlesIn[idx].lifespan.x)/255.);
    break;}
    case 2:
    {x = 3. * size * cos(2. * pi * f32(particlesIn[idx].lifespan.x)/255.);
    y = 3. * size * sin(2. * pi * f32(particlesIn[idx].lifespan.x)/255.);
    break;}
    case 3:
    {x = -3. * size * cos(2. * pi * f32(particlesIn[idx].lifespan.x)/255.);
    y = -3. * size * sin(2. * pi * f32(particlesIn[idx].lifespan.x)/255.);
    break;}
    case 4:
    {x = 3. * size * cos(2. * pi * f32(particlesIn[idx].lifespan.x)/255.);
    y = 3. * size * sin(2. * pi * f32(particlesIn[idx].lifespan.x)/255.);
    break;}
    case 5, default:
    {x = 3. * size * cos(2. * pi * f32(particlesIn[idx].lifespan.x)/255.);
    y = -3. * size * sin(2. * pi * f32(particlesIn[idx].lifespan.x)/255.);
    break;}
  }
  var out: VertexOut;
  //out.pos = vec4f(vec2f(x + particle[0], y + particle[1]), 0, 1);
  out.pos = vec4f(vec2f(x + particle[0], y + particle[1]), 0, 1);
  out.ypos = particle.y;
  return out;
}

fn HSVtoRGB(hue: f32, sat: f32, val: f32) -> vec3f {
  let C : f32 = val * sat;
  let X : f32 = C * (1 - abs( (hue/60. % 2) - 1) );
  let m : f32 = val - C;

  var rgb : vec3f;

  if (hue < 60.) {
    rgb = vec3f(C, X, 0);
  }
  else if (hue < 120.) {
    rgb = vec3f(X, C, 0);
  }
  else if (hue < 180.) {
    rgb = vec3f(0, C, X);
  }
  else if (hue < 240.) {
    rgb = vec3f(0, X, C);
  }
  else if (hue < 300.) {
    rgb = vec3f(X, 0, C);
  }
  else {
    rgb = vec3f(C, 0, X);
  }

  return vec3f((rgb + m) * 255)/255;
}

@fragment
fn fragmentMain(@location(0) ypos: f32) -> @location(0) vec4f {
  let h = (180.f * ypos) + 180.f;
  let s = 1.;
  let v = 1.;

  var rgba = vec4f(HSVtoRGB(h,s,v), 1.);

  return rgba;
  //return vec4f(238.f/255, 118.f/255, 35.f/255, 1); // (R, G, B, A)
}

fn generateWind(time: f32, frequency: f32, strength: f32) -> vec2f {
  //let angle = 3.14159265 * 0.5;
  let angle = sin(time * frequency) * 3.14159265;
  return vec2<f32>(cos(angle), sin(angle)) * strength;
}

@compute @workgroup_size(256)
fn computeMain(@builtin(global_invocation_id) global_id: vec3u) {
  // TODO 6: Revise the compute shader to update the particles using the velocity
  let idx = global_id.x;
  //let p = particlesIn[idx];

  if (idx < arrayLength(&particlesIn)) {
    particlesOut[idx] = particlesIn[idx];
    particlesOut[idx].position = particlesIn[idx].position + particlesIn[idx].velocity;

    let wind = generateWind(f32(particlesIn[idx].position.y), 1.5, 0.00005);
    particlesOut[idx].velocity = particlesIn[idx].velocity + wind;
    /*
    let gravityConstant = -0.001;
    particlesOut[idx].velocity.y = particlesIn[idx].velocity.y + gravityConstant;
    */

    // TOOD 7: Add boundary checking and respawn the particle when it is offscreen
    // abs(particlesOut[idx].position.x) > 1.0 || abs(particlesOut[idx].position.y) > 1.0 || particlesOut[idx].lifespan.x <= 0
    if (particlesOut[idx].lifespan.x <= 0) {
      particlesOut[idx].position = particlesIn[idx].initial_position;
      particlesOut[idx].velocity = particlesIn[idx].initial_velocity;
      particlesOut[idx].lifespan.x = particlesIn[idx].lifespan.y;
    }
    else {
      particlesOut[idx].lifespan.x = particlesIn[idx].lifespan.x - 1;
    }
    
  }
}
