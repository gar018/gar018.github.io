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

// struct to store a multi vector
struct MultiVector {
  s: f32,
  e01: f32,
  eo0: f32,
  eo1: f32
};

// struct to store 2D Camera pose
struct Pose {
  motor: MultiVector,
  scale: vec2f
};

struct Dimensions {
  x: u32
}

fn geometricProduct(a: MultiVector, b: MultiVector) -> MultiVector {
  // ref: https://geometricalgebratutorial.com/pga/
  // eoo = 0, e00 = 1 e11 = 1
  // s + e01 + eo0 + eo1
  // ss   = s   , se01   = e01  , seo0            = eo0  , seo1          = eo1
  // e01s = e01 , e01e01 = -s   , e01eo0 = e10e0o = -eo1 , e01eo1 = -e0o = eo0
  // eo0s = eo0 , eo0e01 = eo1  , eo0eo0          = 0    , eo0eo1        = 0
  // e01s = e01 , eo1e01 = -eo0 , eo1eo0          = 0    , eo1eo1        = 0
  return MultiVector(
    a.s * b.s   - a.e01 * b.e01 , // scalar
    a.s * b.e01 + a.e01 * b.s   , // e01
    a.s * b.eo0 + a.e01 * b.eo1 + a.eo0 * b.s   - a.eo1 * b.e01, // eo0
    a.s * b.eo1 - a.e01 * b.eo0 + a.eo0 * b.e01 + a.eo1 * b.s    // eo1
  );
}
fn reverse(a: MultiVector) -> MultiVector {
  return MultiVector( a.s, -a.e01, -a.eo0, -a.eo1 );
}

fn applyMotor(p: MultiVector, m: MultiVector) -> MultiVector {
  return geometricProduct(m, geometricProduct(p, reverse(m)));
}

fn applyMotorToPoint(p: vec2f, m: MultiVector) -> vec2f {
  // ref: https://geometricalgebratutorial.com/pga/
  // Three basic vectors e0, e1 and eo (origin)
  // Three basic bi-vectors e01, eo0, eo1
  // p = 0 1 + 1 e_01 - x e_o1 + y e_o0 
  // m = c 1 + s e_01 + dx / 2 e_o0 - dy / 2 e_o1 
  let new_p = applyMotor(MultiVector(0, 1, p[0], p[1]), m);
  return vec2f(new_p.eo0 / new_p.e01, new_p.eo1 / new_p.e01);
}

@group(0) @binding(0) var<uniform> camerapose: Pose;
@group(0) @binding(1) var<storage> cellStatusIn: array<u32>;
@group(0) @binding(2) var<storage, read_write> cellStatusOut: array<u32>;
@group(0) @binding(3) var<uniform> gridSize : Dimensions;

struct VertexOutput {
  @builtin(position) pos: vec4f,
  @location(0) cellStatus: f32 // pass the cell status
};

@vertex // this compute the scene coordinate of each input vertex
fn vertexMain(@location(0) pos: vec2f, @builtin(instance_index) idx: u32) -> VertexOutput {

  //TODO allow dynamic grid scaling (first to make it 256x256, then 2048x2048)
  
  //gridSize.x basically refers to 10
  let u = idx % gridSize.x; // we are expecting 10x10, so modulo 10 to get the x index
  let v = idx / gridSize.x; // divide by 10 to get the y index

  // increase the denominator to space each cell more
  let uv = vec2f(f32(u), f32(v)) / f32(gridSize.x); // normalize the coordinates to [0, 1]


  let halfLength = 1.f; // half cell length
  let cellLength = halfLength * 2.f; // full cell length

  // increase the denominator to decrease the SIZE of the quad
  let cell = pos / f32(gridSize.x); // divide the input quad into 10x10 pieces

  let offset = - halfLength + uv * cellLength + cellLength / f32(gridSize.x) * 0.5; // compute the offset for the instance

  
  // Apply motor
  //THESE ADJUST HOW TO POSITION EACH CELL RELATIVE TO THE CAMERA!
  let transformed = applyMotorToPoint(cell + offset, reverse(camerapose.motor));
  // Apply scale
  let scaled = transformed * camerapose.scale;
  var out: VertexOutput;
  out.pos = vec4f(scaled, 0, 1);
  out.cellStatus = f32(cellStatusIn[idx]); //this lets us play with how we color our cell status!
  return out;
}

@fragment // this compute the color of each pixel
fn fragmentMain(@location(0) cellStatus: f32) -> @location(0) vec4f {
  //return vec4f(238.f/255, 118.f/255, 35.f/255, 1) * cellStatus; // (R, G, B, A)
  /*if (cellStatus == 0) {
    return vec4f(0, 0, 0, 1);
  }
  if (cellStatus == 1) {
    return vec4f(1, 0, 0, 1);
  }
  if (cellStatus == 2) {
    return vec4f(1, 0.5, 0, 1);
  }
  if (cellStatus == 3) {
    return vec4f(1, 1, 0, 1);
  }
  if (cellStatus == 4) {
    return vec4f(0, 1, 0, 1);
  }
  if (cellStatus == 5) {
    return vec4f(0, 1, 1, 1);
  }
  if (cellStatus == 6) {
    return vec4f(0, 0, 1, 1);
  }
  if (cellStatus == 7) {
    return vec4f(1, 0, 1, 1);
  }
  if (cellStatus == 8) {
    return vec4f(0.5, 0, 0.5, 1);
  }*/
  return vec4f(1, 1, 1, 1) * cellStatus;
}

@compute
@workgroup_size(8, 8)
fn computeMain(@builtin(global_invocation_id) cell: vec3u) {
  // First count how many neighbors are alive
  let x = cell.x;
  let y = cell.y;
  let RIGHT = (y) * gridSize.x + (x + 1); // index of right neighbor from cell
  let LEFT = (y) * gridSize.x + (x - 1); // index of left neighbor from cell
  let DOWN = (y - 1) * gridSize.x + (x); //POSSIBLY the down neighbor
  let UP = (y + 1) * gridSize.x + (x); //POSSIBLY up neighbor

  let TOP_RIGHT = UP + 1;
  let TOP_LEFT = UP - 1;
  let BOTTOM_RIGHT = DOWN + 1;
  let BOTTOM_LEFT = DOWN - 1;

  let neighborsAlive = cellStatusIn[RIGHT] + cellStatusIn[LEFT] +
                       cellStatusIn[DOWN] + cellStatusIn[UP] +
                       cellStatusIn[TOP_RIGHT] + cellStatusIn[TOP_LEFT] +
                       cellStatusIn[BOTTOM_RIGHT] + cellStatusIn[BOTTOM_LEFT];
  let i = y * gridSize.x + x;
  // Compute new status  
  //life rules:
  //if THIS cell is alive:
  //neighborsAlive < 2 -> this cell is dead
  //neighborsAlive > 3 -> this cell is dead
  //neighborsAlive == 2 or 3 -> this cell stays alive
  //
  //if THIS cell is dead:
  //neighborsAlive == 3 -> this cell becomes alive
  // o/w -> stays dead
  let isAlive = (cellStatusIn[i] == 1);

  if (isAlive) {
    if (neighborsAlive < 2 || neighborsAlive > 3) {
      cellStatusOut[i] = 0;
    }
    else {
      cellStatusOut[i] = 1;
    }
  }
  else { //cell is DEAD
    if (neighborsAlive == 3) {
      cellStatusOut[i] = 1; //cell is alive again
    }
    else {
      cellStatusOut[i] = 0;
    }
  }
  //TODO add 'always dead' cell functionality



  //old status updating scheme
  /*if ((i + neighborsAlive) % 2 == 1) {
    cellStatusOut[i] = 1;
  }
  else {
    cellStatusOut[i] = 0;
  }*/
}
