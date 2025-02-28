class Renderer{constructor(canvas){this._canvas=canvas;this._objects=[];this._clearColor={r:0,g:56/255,b:101/255,a:1};}
async init(){if(!navigator.gpu){throw Error("WebGPU is not supported in this browser.");}
const adapter=await navigator.gpu.requestAdapter();if(!adapter){throw Error("Couldn't request WebGPU adapter.");}
this._device=await adapter.requestDevice();this._context=this._canvas.getContext("webgpu");this._canvasFormat=navigator.gpu.getPreferredCanvasFormat();this._context.configure({device:this._device,format:this._canvasFormat,});this.resizeCanvas();window.addEventListener('resize',this.resizeCanvas.bind(this));}
resizeCanvas(){const devicePixelRatio=window.devicePixelRatio||1;const width=window.innerWidth*devicePixelRatio;const height=window.innerHeight*devicePixelRatio;this._canvas.width=width;this._canvas.height=height;this._canvas.style.width=`${window.innerWidth}px`;this._canvas.style.height=`${window.innerHeight}px`;this._canvas.style.transformOrigin="center";this.render();}
async appendSceneObject(obj){await obj.init();this._objects.push(obj);}
renderToSelectedView(outputView){for(const obj of this._objects){obj?.updateGeometry();}
let encoder=this._device.createCommandEncoder();const pass=encoder.beginRenderPass({colorAttachments:[{view:outputView,clearValue:this._clearColor,loadOp:"clear",storeOp:"store",}]});for(const obj of this._objects){obj?.render(pass);}
pass.end();const computePass=encoder.beginComputePass();for(const obj of this._objects){obj?.compute(computePass);}
computePass.end();const commandBuffer=encoder.finish();this._device.queue.submit([commandBuffer]);}
render(){this.renderToSelectedView(this._context.getCurrentTexture().createView());}}
class SceneObject{static _objectCnt=0;constructor(device,canvasFormat){if(this.constructor==SceneObject){throw new Error("Abstract classes can't be instantiated.");}
this._device=device;this._canvasFormat=canvasFormat;SceneObject._objectCnt+=1;}
getName(){return this.constructor.name+" "+SceneObject._objectCnt.toString();}
async init(){await this.createGeometry();await this.createShaders();await this.createRenderPipeline();await this.createComputePipeline();}
async createGeometry(){throw new Error("Method 'createGeometry()' must be implemented.");}
updateGeometry(){}
loadShader(filename){return new Promise((resolve,reject)=>{const xhttp=new XMLHttpRequest();xhttp.open("GET",filename);xhttp.setRequestHeader("Cache-Control","no-cache, no-store, max-age=0");xhttp.onload=function(){if(xhttp.readyState===XMLHttpRequest.DONE&&xhttp.status===200){resolve(xhttp.responseText);}
else{reject({status:xhttp.status,statusText:xhttp.statusText});}};xhttp.onerror=function(){reject({status:xhttp.status,statusText:xhttp.statusText});};xhttp.send();});}
async createShaders(){throw new Error("Method 'createShaders()' must be implemented.");}
async createRenderPipeline(){throw new Error("Method 'createRenderPipeline()' must be implemented.");}
render(pass){throw new Error("Method 'render(pass)' must be implemented.");}
async createComputePipeline(){throw new Error("Method 'createComputePipeline()' must be implemented.");}
compute(pass){throw new Error("Method 'compute(pass)' must be implemented.");}}
class Standard2DVertexObject extends SceneObject{constructor(device,canvasFormat,vertices){super(device,canvasFormat);this._vertices=vertices;}
async createGeometry(){this._vertexBuffer=this._device.createBuffer({label:"Vertices "+this.getName(),size:this._vertices.byteLength,usage:GPUBufferUsage.VERTEX|GPUBufferUsage.COPY_DST,});this._device.queue.writeBuffer(this._vertexBuffer,0,this._vertices);this._vertexBufferLayout={arrayStride:5*Float32Array.BYTES_PER_ELEMENT,attributes:[{shaderLocation:0,format:"float32x2",offset:0,},{shaderLocation:1,format:"float32x3",offset:2*Float32Array.BYTES_PER_ELEMENT,}],};}
async createShaders(){let shaderCode=await this.loadShader("/shaders/optimized_standard2d.wgsl");this._shaderModule=this._device.createShaderModule({label:" Shader "+this.getName(),code:shaderCode,});}
async createRenderPipeline(){this._renderPipeline=this._device.createRenderPipeline({label:"Render Pipeline "+this.getName(),layout:"auto",vertex:{module:this._shaderModule,entryPoint:"vertexMain",buffers:[this._vertexBufferLayout]},fragment:{module:this._shaderModule,entryPoint:"fragmentMain",targets:[{format:this._canvasFormat}]}});}
render(pass){pass.setPipeline(this._renderPipeline);pass.setVertexBuffer(0,this._vertexBuffer);pass.draw(this._vertices.length/5);}
async createComputePipeline(){}
compute(pass){}}
async function createCircleGeometry(x,y,radius,numSegments){}
async function init(){const canvasTag=document.createElement('canvas');canvasTag.id="renderCanvas";document.body.appendChild(canvasTag);const renderer=new Renderer(canvasTag);await renderer.init();var vertices=new Float32Array([0,0.5,0.85,0,0,-0.5,0,0.85,0,0,0.5,0,0.85,0,0,]);await renderer.appendSceneObject(new Standard2DVertexObject(renderer._device,renderer._canvasFormat,vertices));var verticesSquare1=new Float32Array([-0.5,-0.1,0,0.85,0,-0.5,-0.6,0,0.85,0,0,-0.6,0,0.85,0,0,-0.1,0,0.85,0,-0.5,-0.1,0,0.85,0,0,-0.6,0,0.85,0,]);await renderer.appendSceneObject(new Standard2DVertexObject(renderer._device,renderer._canvasFormat,verticesSquare1));var verticesStar1=new Float32Array([0.3,-0.1,0,0,0.85,0.1,-0.45,0,0,0.85,0.5,-0.45,0,0,0.85,0.1,-0.25,0,0,0.85,0.5,-0.25,0,0,0.85,0.3,-0.6,0,0,0.85,]);await renderer.appendSceneObject(new Standard2DVertexObject(renderer._device,renderer._canvasFormat,verticesStar1));renderer.render();return renderer;}
init().then(ret=>{console.log(ret);}).catch(error=>{const pTag=document.createElement('p');pTag.innerHTML=navigator.userAgent+"</br>"+error.message;document.body.appendChild(pTag);document.getElementById("renderCanvas").remove();});