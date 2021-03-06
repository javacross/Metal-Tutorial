//
//  Renderer.swift
//  Metal Tutorial
//
//  Created by Sharp, Keith on 5/7/19.
//  Copyright © 2019 Passback Systems. All rights reserved.
//

import MetalKit

class Renderer: NSObject {
    
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let pipelineState: MTLRenderPipelineState
    
    var texturedModel: TexturedModel?
    var uniforms = Uniforms()
    
    init?(mtkView: MTKView) {
        device = mtkView.device!
        guard let tmpCommandQueue = device.makeCommandQueue() else {
            return nil
        }
        commandQueue = tmpCommandQueue
        pipelineState = Renderer.createRenderPipeline(mtkView: mtkView)
    }
    
    class func createRenderPipeline(mtkView: MTKView) -> MTLRenderPipelineState {
        let library = mtkView.device?.makeDefaultLibrary()
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertex_main")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragment_main")
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        
        guard let ps = try! mtkView.device?.makeRenderPipelineState(descriptor: pipelineDescriptor) else {
            fatalError("Could not make RenderPipelineState")
        }
        
        return ps
    }
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        guard let model = texturedModel else { return }
        
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 0, 1)
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        renderEncoder.setFragmentTexture(model.texture, index: 0)
        renderEncoder.setVertexBuffer(model.rawModel.vertexBuffer, offset: 0, index: model.rawModel.bufferIndex)
        
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        renderEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        
        renderEncoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: model.rawModel.count,
                                            indexType: .uint16,
                                            indexBuffer: model.rawModel.indexBuffer,
                                            indexBufferOffset: 0)
        
        renderEncoder.endEncoding()
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()

    }
}
