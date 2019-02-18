//
//  MGLKViewController.m
//  GLViewDemo
//
//  Created by HW on 2019/1/29.
//  Copyright © 2019 meitu. All rights reserved.
//

#import "MGLKViewController.h"
#define STRING(x) #x

static const char* vertShaderStr = STRING
(
 attribute vec4 position;
 attribute vec2 texCoord;
 varying highp vec2 coord;
 uniform mat4 matrix;
 void main()
{
    coord = texCoord;
    gl_Position = matrix * position;
}
 );

static const char* fragShaderStr = STRING
(
#ifdef GL_ES//for discriminate GLES & GL
#ifdef GL_FRAGMENT_PRECISION_HIGH
 precision highp float;
#else
 precision mediump float;
#endif
#else
#define highp
#define mediump
#define lowp
#endif
 varying highp vec2 coord;
 uniform sampler2D colorMap;
 void main()
{
    gl_FragColor = texture2D(colorMap, coord.st);
}
 );


//矩形的六个顶点
static const GLfloat vertices[] = {
    1.0f, 1.0f, -1.0f,          1.0f, 1.0f,
    -1.0f, 1.0f, -1.0f,         0.0f, 1.0f,
    1.0f, -1.0f, -1.0f,         1.0f, 0.0f,
    
    1.0f, -1.0f, -1.0f,         1.0f, 0.0f,
    -1.0f, 1.0f, -1.0f,         0.0f, 1.0f,
    -1.0f, -1.0f, -1.0f,        0.0f, 0.0f,
};



@interface MGLKViewController ()
@property (nonatomic,strong)GLKBaseEffect *baseEffect;
//声明缓存ID属性
@property (nonatomic,assign)GLuint vertextBufferID;
@property (nonatomic,assign)GLuint texture;
@property (nonatomic,assign)GLuint program;
@property (nonatomic,assign)CGSize imageSize;
@end

@implementation MGLKViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    GLKView *view  = (GLKView *)self.view;
    //创建OpenGL ES2.0上下文
    view.context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    //设置当前上下文
    [EAGLContext setCurrentContext:view.context];
    
    _baseEffect = [[GLKBaseEffect alloc]init];
    //使用静态颜色绘制
    _baseEffect.useConstantColor = GL_TRUE;
    //设置默认绘制颜色，参数分别是 RGBA
    _baseEffect.constantColor = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
    
    //viewdidload中生成并绑定缓存数据
    glGenBuffers(1, &_vertextBufferID);
    glBindBuffer(GL_ARRAY_BUFFER, _vertextBufferID); //绑定指定标识符的缓存为当前缓存
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 4*5, (char*)NULL+0);
    
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 4*5, (char*)NULL+12);
    
    
    NSString* path = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"大图.jpg"];
    UIImage* image = [[UIImage alloc] initWithContentsOfFile:path];
    _imageSize = image.size;
    unsigned char* pData = RGBADataWithAlpha(image);
    imageWithRGBAData(pData, _imageSize.width, _imageSize.height);
    _texture = LoadTexture_BYTE(pData, image.size.width, image.size.height, GL_RGBA);
    
    loadTextureToUIImage(_texture, _imageSize.width, _imageSize.height);
    
    image = nil;
//    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], GLKTextureLoaderOriginBottomLeft, nil];
//    GLKTextureInfo* textureInfo = [GLKTextureLoader textureWithContentsOfFile:path options:options error:nil];
//    _baseEffect.texture2d0.enabled = GL_TRUE;
//    _baseEffect.texture2d0.name = textureInfo.name;

    GLenum e = glGetError();
    
    _program = [self loadShaders:vertShaderStr frag:fragShaderStr];
    e = glGetError();
    GLint params;
    glGetProgramiv(_program, GL_LINK_STATUS, &params);

    glBindAttribLocation(_program, 0, "position");
    glBindAttribLocation(_program, 3, "texCoord");
    glLinkProgram(_program);
    glUseProgram(_program);
    GLint colorMap = glGetUniformLocation(_program, "colorMap");
    glUniform1i(colorMap, 0);
    
    e = glGetError();
    
    NSLog(@"1");
    
    
    self.view.userInteractionEnabled = YES;
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeSelfView:)];
    [self.view addGestureRecognizer:tapGesture];
    
    
}


- (void)removeSelfView:(UITapGestureRecognizer *)gesture {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    [self.baseEffect prepareToDraw];
    
    //设置背景色为黑色
    glClearColor(0.0f,0.0f,0.0f,1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //绘图
    glUseProgram(_program);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _texture);
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    loadTextureToUIImage(_texture, _imageSize.width, _imageSize.height);
    
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
}

- (void)update {
    float aspect = std::abs(_imageSize.width / _imageSize.height);
    GLKMatrix4 projectMatrix = GLKMatrix4Identity;
    projectMatrix = GLKMatrix4Scale(projectMatrix, 1.0f, aspect, 1.0f);
    GLint mat = glGetUniformLocation(_program, "matrix");
    glUniformMatrix4fv(mat, 1, GL_FALSE, projectMatrix.m);
}


- (void)dealloc{
    GLKView *view = (GLKView *)self.view;
    [EAGLContext setCurrentContext:view.context];
    if ( 0 != _vertextBufferID) {
        glDeleteBuffers(1,
                        &_vertextBufferID);
        _vertextBufferID = 0;
    }
    
    glDeleteTextures(1, &_texture);
    glDeleteProgram(_program);
}




- (GLint)loadShaders:(const char*)vert frag:(const char*)frag {
    GLuint vertShader, fragShader;
    GLint compiled;
    GLint program = glCreateProgram();
    
    const GLchar* vertStr = (GLchar*)vert;
    const GLchar* fragStr = (GLchar*)frag;
    
    vertShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertShader, 1, &vertStr, NULL);
    glCompileShader(vertShader);
    
    glGetShaderiv(vertShader, GL_COMPILE_STATUS, &compiled);
    if (!compiled) {
        GLint infoLen = 0;// 查询日志的长度判断是否有日志产生
        glGetShaderiv(vertShader, GL_INFO_LOG_LENGTH, &infoLen);
        if (infoLen > 1) {// 分配一个足以存储日志信息的字符串
            char* infoLog = (char *) malloc(sizeof(char) * infoLen);// 检索日志信息
            glGetShaderInfoLog(vertShader, infoLen, nullptr, infoLog);
            NSLog(@"Error compiling shader:\n%s\n", infoLog);// 使用完成后需要释放字符串分配的任务
            free(infoLog);
        }
        glDeleteShader(vertShader);
        return 0;
    }
        
    
    fragShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragShader, 1, &fragStr, NULL);
    glCompileShader(fragShader);
    
    glGetShaderiv(fragShader, GL_COMPILE_STATUS, &compiled);
    if (!compiled) {
        GLint infoLen = 0;// 查询日志的长度判断是否有日志产生
        glGetShaderiv(fragShader, GL_INFO_LOG_LENGTH, &infoLen);
        if (infoLen > 1) {// 分配一个足以存储日志信息的字符串
            char* infoLog = (char *) malloc(sizeof(char) * infoLen);// 检索日志信息
            glGetShaderInfoLog(fragShader, infoLen, nullptr, infoLog);
            NSLog(@"Error compiling shader:\n%s\n", infoLog);// 使用完成后需要释放字符串分配的任务
            free(infoLog);
        }
        glDeleteShader(fragShader);
        return 0;
    }
    
    glAttachShader(program, vertShader);
    glAttachShader(program, fragShader);
    
    glLinkProgram(program);
    
    return program;
}

//Alpha为原始图像的透明度
unsigned char* RGBADataWithAlpha(UIImage* image)
{
    CGImageAlphaInfo info = CGImageGetAlphaInfo(image.CGImage);
    BOOL hasAlpha = ((info == kCGImageAlphaPremultipliedLast) ||
                     (info == kCGImageAlphaPremultipliedFirst) ||
                     (info == kCGImageAlphaLast) ||
                     (info == kCGImageAlphaFirst) ? YES : NO);
    
    long width = CGImageGetWidth(image.CGImage);
    long height = CGImageGetHeight(image.CGImage);
    if(width == 0 || height == 0)
        return 0;
    unsigned char* imageData = (unsigned char *) malloc(4 * width * height);
    
    CGColorSpaceRef cref = CGColorSpaceCreateDeviceRGB();
    CGContextRef gc = CGBitmapContextCreate(imageData,
                                            width,height,
                                            8,width*4,
                                            cref,kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(cref);
    UIGraphicsPushContext(gc);
    
    if (hasAlpha == YES)
    {
        CGContextSetRGBFillColor(gc, 1.0, 1.0, 1.0, 1.0);
        CGContextFillRect(gc, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height));
    }
    CGRect rect = {{ 0 , 0 }, {(CGFloat)width, (CGFloat)height }};
    CGContextDrawImage( gc, rect, image.CGImage );
    UIGraphicsPopContext();
    CGContextRelease(gc);
    
    
    
    if (hasAlpha == YES)
    {
        unsigned char array[256][256] = {0};
        for (int j=1; j<256; j++)
        {
            for (int i=0; i<256; i++)
            {
                array[j][i] = fmin(fmax(0.0f,(j+i-255)*255.0/i+0.5),255.0f);
            }
        }
        GLubyte* alphaData = (GLubyte*) calloc(width * height, sizeof(GLubyte));
        CGContextRef alphaContext = CGBitmapContextCreate(alphaData, width, height, 8, width, NULL, kCGImageAlphaOnly);
        CGContextDrawImage(alphaContext, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), image.CGImage);
        // Draw the image into the bitmap context
        CGContextRelease(alphaContext);
        GLubyte* pDest = imageData;
        GLubyte* alphaTemp = alphaData;
        for (int j=0; j<height; j++)
        {
            for (int i=0; i<width; i++)
            {
                
                //自己反计算回原来的alpha值
                pDest[0] = array[pDest[0]][alphaTemp[0]];
                pDest[1] = array[pDest[1]][alphaTemp[0]];
                pDest[2] = array[pDest[2]][alphaTemp[0]];
                
                pDest[3] = alphaTemp[0];
                pDest += 4;
                alphaTemp++;
            }
        }
        free(alphaData);
    }
    
    
    return imageData;// CGBitmapContextGetData(gc);
}


GLuint LoadTexture_BYTE(GLubyte* pdata, int width, int height, GLenum glFormat)
{
    GLuint textures;
    glGenTextures(1, &textures);
    if (textures != 0)
    {
        glBindTexture(GL_TEXTURE_2D, textures);
        if (glFormat == GL_LUMINANCE)
        {
            glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
            glTexImage2D(GL_TEXTURE_2D, 0, glFormat, width, height, 0, glFormat, GL_UNSIGNED_BYTE, pdata);
            glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
        }
        else
        {
            glTexImage2D(GL_TEXTURE_2D, 0, glFormat, width, height, 0, glFormat, GL_UNSIGNED_BYTE, pdata);
        }
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        return textures;
    }
    else
    {
        return 0;
    }
}

UIImage* imageWithRGBAData(unsigned char*data, int width, int height)
{
    // Create a bitmap context with the image data
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(data, width, height, 8, width*4, colorspace, kCGImageAlphaPremultipliedLast);
    CGImageRef cgImage = nil;
    if (context != nil) {
        cgImage = CGBitmapContextCreateImage (context);
        CGContextRelease(context);
    }
    CGColorSpaceRelease(colorspace);
    
    UIImage * image = nil;
    
    if(cgImage != nil)
        image = [[UIImage alloc] initWithCGImage:cgImage];
    
    // Release the cgImage when done
    CGImageRelease(cgImage);
    return image;
}

void loadTextureToUIImage(GLuint texture, int width, int height)
{
    GLint lastFBO[1];
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, lastFBO);
    GLint lastViewport[4];
    glGetIntegerv(GL_VIEWPORT, lastViewport);
    
    GLuint fbo;
    glGenFramebuffers(1, &fbo);
    //绑定framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
    glViewport(0, 0, width, height);
    unsigned char *pData = new unsigned char[width * height << 2];
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, pData);
    imageWithRGBAData(pData, width, height);
    delete [] pData;
    pData = NULL;
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, 0, 0);
    glDeleteFramebuffers(1, &fbo);
    
    glBindFramebuffer(GL_FRAMEBUFFER, lastFBO[0]);
    glViewport(lastViewport[0], lastViewport[1], lastViewport[2], lastViewport[3]);
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
