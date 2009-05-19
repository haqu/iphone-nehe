#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import "Texture2D.h"

#define kFPS 60.0

@interface EAGLView : UIView {
    
@private
	GLint backingWidth;
	GLint backingHeight;

	EAGLContext *context;

	GLuint viewRenderbuffer;
	GLuint viewFramebuffer;
	GLuint depthRenderbuffer;

	NSTimer *animationTimer;
	NSTimeInterval animationInterval;

	CFTimeInterval currentTime;
	CFTimeInterval lastTime;
	
	Texture2D *cubeTexture;
	
	GLfloat xRotation;
	GLfloat yRotation;
	
	BOOL lightingEnabled;
	BOOL antialiasEnabled;
}

@property NSTimeInterval animationInterval;

- (void)startAnimation;
- (void)stopAnimation;

@end
