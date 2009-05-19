#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "EAGLView.h"

#define USE_DEPTH_BUFFER 1

@interface EAGLView ()
@property (nonatomic, retain) EAGLContext *context;
@property (nonatomic, assign) NSTimer *animationTimer;

- (BOOL)createFramebuffer;
- (void)destroyFramebuffer;
- (void)initGL;
- (void)initTextures;
- (void)gameLoop;
- (void)updateScene:(float)delta;
- (void)renderScene;
- (void)renderCube;

@end


@implementation EAGLView

@synthesize context;
@synthesize animationTimer;
@synthesize animationInterval;

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder*)coder {

	if((self = [super initWithCoder:coder])) {
		CAEAGLLayer *eaglLayer = (CAEAGLLayer*)self.layer;
		eaglLayer.opaque = YES;
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];

		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];

		if(!context || ![EAGLContext setCurrentContext:context]) {
			[self release];
			return nil;
		}

		animationInterval = 1.0 / 60.0;

		lastTime = CFAbsoluteTimeGetCurrent();
		
		xRotation = 0.0f;
		yRotation = 0.0f;
				
		[self initGL];
		[self initTextures];
	}
	return self;
}

void gluPerspective(GLfloat fovy, GLfloat aspect, GLfloat zNear, GLfloat zFar) {
	
	GLfloat xmin, xmax, ymin, ymax;
	
	ymax = zNear * tan(fovy * M_PI / 360.0f);
	ymin = -ymax;
	xmin = ymin * aspect;
	xmax = ymax * aspect;
	
	glFrustumf(xmin, xmax, ymin, ymax, zNear, zFar);
}

- (void)initGL {
	
	CGRect rect = [[UIScreen mainScreen] bounds];
	
	glViewport(0, 0, rect.size.width, rect.size.height);
	
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	
	GLfloat aspect = (GLfloat)rect.size.width / (GLfloat)rect.size.height;
	gluPerspective(45.0, aspect, 0.1, 100.0);
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	glEnable(GL_TEXTURE_2D);
	glShadeModel(GL_SMOOTH);
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	glClearDepthf(1.0f);
	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LEQUAL);
	
	// lighting
	
	GLfloat lightAmbient[]  = { 0.1f, 0.1f, 0.1f, 1.0f };
	GLfloat lightDiffuse[]  = { 1.0f, 1.0f, 1.0f, 1.0f };
	GLfloat lightPosition[] = { 0.0f, 0.0f, 2.0f, 1.0f };
	
	glLightfv(GL_LIGHT1, GL_AMBIENT, lightAmbient);
	glLightfv(GL_LIGHT1, GL_DIFFUSE, lightDiffuse);
	glLightfv(GL_LIGHT1, GL_POSITION, lightPosition);
	glEnable(GL_LIGHT1);
	
	glEnable(GL_LIGHTING);
	
	// materials
	
	GLfloat materialAmbient[] = { 0.2f, 0.2f, 0.2f, 1.0f };
	GLfloat materialDiffuse[] = { 0.8f, 0.8f, 0.8f, 1.0f };
	
	glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, materialAmbient);
	glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, materialDiffuse);	
}

- (void)initTextures {
	cubeTexture = [[Texture2D alloc] initWithImage:[UIImage imageNamed:@"crate.bmp"]];
}

- (void)gameLoop {
	
	float delta;
	currentTime = CFAbsoluteTimeGetCurrent();
	delta = (currentTime - lastTime);
	lastTime = currentTime;
	
	[self updateScene:delta];
	[self renderScene];
}

- (void)updateScene:(float)delta {

	yRotation += 25.0f * delta;

	static float amplitude = 0.0f;
	if(amplitude < 80.0f) amplitude += 5.0f * delta;
	xRotation = amplitude * (float)sin(0.4 * currentTime) * 2.0f;
}

- (void)renderScene {
    
	[EAGLContext setCurrentContext:context];

	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glLoadIdentity();
	
	[self renderCube];
	
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

- (void)renderCube {
	
	glTranslatef(0.0f, 0.0f, -7.0f);
	
	glRotatef(xRotation, 1.0f, 0.0f, 0.0f);
	glRotatef(yRotation, 0.0f, 1.0f, 0.0f);
	
	glBindTexture(GL_TEXTURE_2D, cubeTexture.name);
	
	GLfloat vertices[4][3];
	GLfloat normals[4][3];
	GLfloat texCoords[4][2];
	GLubyte indices[4] = { 0, 1, 3, 2 };
	
	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glNormalPointer(GL_FLOAT, 0, normals);
	glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
	
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_NORMAL_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	
	// front face
	
	vertices[0][0] = -1.0f; vertices[0][1] = -1.0f; vertices[0][2] = 1.0f;
	vertices[1][0] =  1.0f; vertices[1][1] = -1.0f; vertices[1][2] = 1.0f;
	vertices[2][0] =  1.0f; vertices[2][1] =  1.0f; vertices[2][2] = 1.0f;
	vertices[3][0] = -1.0f; vertices[3][1] =  1.0f; vertices[3][2] = 1.0f;
	
	normals[0][0] = normals[1][0] = normals[2][0] = normals[3][0] = 0.0f;
	normals[0][1] = normals[1][1] = normals[2][1] = normals[3][1] = 0.0f;
	normals[0][2] = normals[1][2] = normals[2][2] = normals[3][2] = 1.0f;

	texCoords[0][0] = 0.0f; texCoords[0][1] = 1.0f;
	texCoords[1][0] = 1.0f; texCoords[1][1] = 1.0f;
	texCoords[2][0] = 1.0f; texCoords[2][1] = 0.0f;
	texCoords[3][0] = 0.0f; texCoords[3][1] = 0.0f;
	
	glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_BYTE, indices);

	// back face
	
	vertices[0][0] =  1.0f; vertices[0][1] = -1.0f; vertices[0][2] = -1.0f;
	vertices[1][0] = -1.0f; vertices[1][1] = -1.0f; vertices[1][2] = -1.0f;
	vertices[2][0] = -1.0f; vertices[2][1] =  1.0f; vertices[2][2] = -1.0f;
	vertices[3][0] =  1.0f; vertices[3][1] =  1.0f; vertices[3][2] = -1.0f;
	
	normals[0][0] = normals[1][0] = normals[2][0] = normals[3][0] =  0.0f;
	normals[0][1] = normals[1][1] = normals[2][1] = normals[3][1] =  0.0f;
	normals[0][2] = normals[1][2] = normals[2][2] = normals[3][2] = -1.0f;
	
	texCoords[0][0] = 0.0f; texCoords[0][1] = 1.0f;
	texCoords[1][0] = 1.0f; texCoords[1][1] = 1.0f;
	texCoords[2][0] = 1.0f; texCoords[2][1] = 0.0f;
	texCoords[3][0] = 0.0f; texCoords[3][1] = 0.0f;
	
	glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_BYTE, indices);

	// top face
	
	vertices[0][0] = -1.0f; vertices[0][1] = 1.0f; vertices[0][2] =  1.0f;
	vertices[1][0] =  1.0f; vertices[1][1] = 1.0f; vertices[1][2] =  1.0f;
	vertices[2][0] =  1.0f; vertices[2][1] = 1.0f; vertices[2][2] = -1.0f;
	vertices[3][0] = -1.0f; vertices[3][1] = 1.0f; vertices[3][2] = -1.0f;
	
	normals[0][0] = normals[1][0] = normals[2][0] = normals[3][0] = 0.0f;
	normals[0][1] = normals[1][1] = normals[2][1] = normals[3][1] = 1.0f;
	normals[0][2] = normals[1][2] = normals[2][2] = normals[3][2] = 0.0f;
	
	texCoords[0][0] = 1.0f; texCoords[0][1] = 1.0f;
	texCoords[1][0] = 0.0f; texCoords[1][1] = 1.0f;
	texCoords[2][0] = 0.0f; texCoords[2][1] = 0.0f;
	texCoords[3][0] = 1.0f; texCoords[3][1] = 0.0f;

	glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_BYTE, indices);
	
	// bottom face
	
	vertices[0][0] = -1.0f; vertices[0][1] = -1.0f; vertices[0][2] = -1.0f;
	vertices[1][0] =  1.0f; vertices[1][1] = -1.0f; vertices[1][2] = -1.0f;
	vertices[2][0] =  1.0f; vertices[2][1] = -1.0f; vertices[2][2] =  1.0f;
	vertices[3][0] = -1.0f; vertices[3][1] = -1.0f; vertices[3][2] =  1.0f;
	
	normals[0][0] = normals[1][0] = normals[2][0] = normals[3][0] =  0.0f;
	normals[0][1] = normals[1][1] = normals[2][1] = normals[3][1] = -1.0f;
	normals[0][2] = normals[1][2] = normals[2][2] = normals[3][2] =  0.0f;
	
	texCoords[0][0] = 1.0f; texCoords[0][1] = 1.0f;
	texCoords[1][0] = 0.0f; texCoords[1][1] = 1.0f;
	texCoords[2][0] = 0.0f; texCoords[2][1] = 0.0f;
	texCoords[3][0] = 1.0f; texCoords[3][1] = 0.0f;
	
	glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_BYTE, indices);
	
	// right face
	
	vertices[0][0] = 1.0f; vertices[0][1] = -1.0f; vertices[0][2] =  1.0f;
	vertices[1][0] = 1.0f; vertices[1][1] = -1.0f; vertices[1][2] = -1.0f;
	vertices[2][0] = 1.0f; vertices[2][1] =  1.0f; vertices[2][2] = -1.0f;
	vertices[3][0] = 1.0f; vertices[3][1] =  1.0f; vertices[3][2] =  1.0f;
	
	normals[0][0] = normals[1][0] = normals[2][0] = normals[3][0] = 1.0f;
	normals[0][1] = normals[1][1] = normals[2][1] = normals[3][1] = 0.0f;
	normals[0][2] = normals[1][2] = normals[2][2] = normals[3][2] = 0.0f;
	
	texCoords[0][0] = 1.0f; texCoords[0][1] = 1.0f;
	texCoords[1][0] = 0.0f; texCoords[1][1] = 1.0f;
	texCoords[2][0] = 0.0f; texCoords[2][1] = 0.0f;
	texCoords[3][0] = 1.0f; texCoords[3][1] = 0.0f;
	
	glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_BYTE, indices);

	// left face
	
	vertices[0][0] = -1.0f; vertices[0][1] = -1.0f; vertices[0][2] = -1.0f;
	vertices[1][0] = -1.0f; vertices[1][1] = -1.0f; vertices[1][2] =  1.0f;
	vertices[2][0] = -1.0f; vertices[2][1] =  1.0f; vertices[2][2] =  1.0f;
	vertices[3][0] = -1.0f; vertices[3][1] =  1.0f; vertices[3][2] = -1.0f;
	
	normals[0][0] = normals[1][0] = normals[2][0] = normals[3][0] = -1.0f;
	normals[0][1] = normals[1][1] = normals[2][1] = normals[3][1] =  0.0f;
	normals[0][2] = normals[1][2] = normals[2][2] = normals[3][2] =  0.0f;
	
	texCoords[0][0] = 1.0f; texCoords[0][1] = 1.0f;
	texCoords[1][0] = 0.0f; texCoords[1][1] = 1.0f;
	texCoords[2][0] = 0.0f; texCoords[2][1] = 0.0f;
	texCoords[3][0] = 1.0f; texCoords[3][1] = 0.0f;
	
	glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_BYTE, indices);
	
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_NORMAL_ARRAY);
	glDisableClientState(GL_VERTEX_ARRAY);
}

- (void)layoutSubviews {
	[EAGLContext setCurrentContext:context];
	[self destroyFramebuffer];
	[self createFramebuffer];
	[self renderScene];
}

- (BOOL)createFramebuffer {

	glGenFramebuffersOES(1, &viewFramebuffer);
	glGenRenderbuffersOES(1, &viewRenderbuffer);

	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);

	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);

	if(USE_DEPTH_BUFFER) {
		glGenRenderbuffersOES(1, &depthRenderbuffer);
		glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
		glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
		glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
	}

	if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
		return NO;
	}

	return YES;
}

- (void)destroyFramebuffer {
    
	glDeleteFramebuffersOES(1, &viewFramebuffer);
	viewFramebuffer = 0;
	glDeleteRenderbuffersOES(1, &viewRenderbuffer);
	viewRenderbuffer = 0;

	if(depthRenderbuffer) {
		glDeleteRenderbuffersOES(1, &depthRenderbuffer);
		depthRenderbuffer = 0;
	}
}

- (void)startAnimation {
	self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:animationInterval target:self selector:@selector(gameLoop) userInfo:nil repeats:YES];
}

- (void)stopAnimation {
	self.animationTimer = nil;
}

- (void)setAnimationTimer:(NSTimer *)newTimer {
	[animationTimer invalidate];
	animationTimer = newTimer;
}

- (void)setAnimationInterval:(NSTimeInterval)interval {
	animationInterval = interval;
	if(animationTimer) {
		[self stopAnimation];
		[self startAnimation];
	}
}

- (void)dealloc {
    
	[self stopAnimation];

	if([EAGLContext currentContext] == context) {
		[EAGLContext setCurrentContext:nil];
	}

	[cubeTexture release];
	[context release];  
	[super dealloc];
}

@end
