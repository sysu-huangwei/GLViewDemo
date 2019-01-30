//
//  MGLKViewController.m
//  GLViewDemo
//
//  Created by HW on 2019/1/29.
//  Copyright © 2019 meitu. All rights reserved.
//

#import "MGLKViewController.h"


static NSString* vertShaderStr = @"\
attribute vec4 position; \n \
attribute vec2 texCoord; \n \
varying highp vec2 coord; \n \
uniform mat4 matrix; \n \
void main() \n \
{ \n \
    coord = texCoord; \n \
    gl_Position = matrix * position; \n \
} \n";

static NSString* fragShaderStr = @"\
#ifdef GL_ES//for discriminate GLES & GL  \n \
#ifdef GL_FRAGMENT_PRECISION_HIGH  \n \
precision highp float;  \n \
#else  \n \
precision mediump float;  \n \
#endif  \n \
#else  \n \
#define highp  \n \
#define mediump  \n \
#define lowp  \n \
#endif  \n \
varying vec2 coord; \n \
uniform sampler2D colorMap; \n \
void main() \n \
{ \n \
    gl_FragColor = texture2D(colorMap, coord.st); \n \
} \n";


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
    image = nil;
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], GLKTextureLoaderOriginBottomLeft, nil];
    GLKTextureInfo* textureInfo = [GLKTextureLoader textureWithContentsOfFile:path options:options error:nil];
    _baseEffect.texture2d0.enabled = GL_TRUE;
    _baseEffect.texture2d0.name = textureInfo.name;

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
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
}

- (void)update {
    float aspect = fabsf(_imageSize.width / _imageSize.height);
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
}




- (GLint)loadShaders:(NSString*)vert frag:(NSString*)frag {
    GLuint vertShader, fragShader;
    GLint compiled;
    GLint program = glCreateProgram();
    
    const GLchar* vertStr = (GLchar*)[vert UTF8String];
    const GLchar* fragStr = (GLchar*)[frag UTF8String];
    
    vertShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertShader, 1, &vertStr, NULL);
    glCompileShader(vertShader);
    
    glGetShaderiv(vertShader, GL_COMPILE_STATUS, &compiled);
    if (!compiled) {
        GLint  infoLen = 0;// 查询日志的长度判断是否有日志产生
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
        GLint  infoLen = 0;// 查询日志的长度判断是否有日志产生
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



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
