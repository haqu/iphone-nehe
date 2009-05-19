#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import "Texture2D.h"

@interface EAGLView : UIView {
    
@private

	GLint backingWidth;
	GLint backingHeight;

	EAGLContext *context;

	GLuint viewRenderbuffer, viewFramebuffer;
	GLuint depthRenderbuffer;

	NSTimer *animationTimer;
	NSTimeInterval animationInterval;

	CFTimeInterval currentTime;
	CFTimeInterval lastTime;
	
	Texture2D *cubeTexture;
	
	GLfloat xRotation;
	GLfloat yRotation;
}

@property NSTimeInterval animationInterval;

- (void)startAnimation;
- (void)stopAnimation;

@end
