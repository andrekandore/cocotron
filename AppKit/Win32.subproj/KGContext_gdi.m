#import "KGContext_gdi.h"
#import "KGLayer_gdi.h"
#import "KGRenderingContext_gdi.h"
#import "KGGraphicsState_gdi.h"
#import "Win32Window.h"
#import <AppKit/KGDeviceContext_gdi.h>
#import <AppKit/KGMutablePath.h>
#import <AppKit/KGColor.h>
#import <AppKit/KGFont.h>

@implementation KGContext_gdi

-initWithSize:(NSSize)size window:(CGWindow *)window {
   HWND                    handle=[(Win32Window *)window windowHandle];
   KGRenderingContext_gdi *rc=[KGRenderingContext_gdi renderingContextWithWindowHWND:handle];
   CGAffineTransform       flip={1,0,0,-1,0,size.height};
   KGGraphicsState        *initialState=[[[KGGraphicsState_gdi alloc] initWithRenderingContext:rc transform:flip] autorelease];

   [self initWithGraphicsState:initialState];

   _renderingContext=[rc retain];
   
   return self;
}

-initWithSize:(NSSize)size context:(KGContext *)otherX {
   KGContext_gdi          *other=(KGContext_gdi *)otherX;
   KGRenderingContext_gdi *rc=[KGRenderingContext_gdi renderingContextWithSize:size renderingContext:[other renderingContext]];
   CGAffineTransform       flip={1,0,0,-1,0,size.height};
   KGGraphicsState        *initialState=[[[KGGraphicsState_gdi alloc] initWithRenderingContext:rc transform:flip] autorelease];

   [self initWithGraphicsState:initialState];

   _renderingContext=[rc retain];
   
   return self;
}

-(void)dealloc {
   [_renderingContext release];
   [super dealloc];
}

-(KGGraphicsState_gdi *)currentState {
   return [_stateStack lastObject];
}

-(KGRenderingContext_gdi *)renderingContext {
   return _renderingContext;
}

-(void)strokeRect:(NSRect)rect {
   [self strokeRect:rect width:[self currentState]->_lineWidth];
}

-(void)strokeRect:(NSRect)rect width:(float)width {
   [[self renderingContext] strokeInUserSpace:[self currentState]->_ctm rect:rect width:width color:[self currentState]->_strokeColor];
}

-(void)fillRects:(const NSRect *)rects count:(unsigned)count {
   [[self renderingContext] fillInUserSpace:[self currentState]->_ctm rects:rects count:count color:[self currentState]->_fillColor];
}

-(void)drawPath:(CGPathDrawingMode)pathMode {
   [[self renderingContext] drawPathInDeviceSpace:_path drawingMode:pathMode ctm:[self currentState]->_ctm lineWidth:[self currentState]->_lineWidth fillColor:[self currentState]->_fillColor strokeColor:[self currentState]->_strokeColor];

   [_path reset];
}

-(void)setFont:(KGFont *)font {
   [super setFont:font];
   [[self renderingContext] setFont:font];
}

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count {
   [[self renderingContext] showInUserSpace:[self currentState]->_ctm textSpace:[self currentState]->_textTransform glyphs:glyphs count:count color:[self currentState]->_fillColor];
   
   NSSize advancement;
   
   advancement=[[self currentFont] advancementForNominalGlyphs:glyphs count:count];
   
   [self currentState]->_textTransform.tx+=advancement.width;
   [self currentState]->_textTransform.ty+=advancement.height;
}

-(void)drawShading:(KGShading *)shading {
   [[self renderingContext] drawInUserSpace:[self currentState]->_ctm shading:shading];
}

-(void)drawImage:(KGImage *)image inRect:(NSRect)rect {
   [[self renderingContext] drawImage:image inRect:rect ctm:[self currentState]->_ctm fraction:[[self currentState]->_fillColor alpha]];
}

-(void)drawLayer:(KGLayer *)layer inRect:(NSRect)rect {
   [[self renderingContext] drawLayer:layer inRect:rect ctm:[self currentState]->_ctm];
}

-(void)copyBitsInRect:(NSRect)rect toPoint:(NSPoint)point gState:(int)gState {
   [[self renderingContext] copyBitsInUserSpace:[self currentState]->_ctm rect:rect toPoint:point];
}

-(KGLayer *)layerWithSize:(NSSize)size unused:(NSDictionary *)unused {
   return [[[KGLayer_gdi alloc] initRelativeToRenderingContext:[self renderingContext] size:size unused:unused] autorelease];
}

-(void)beginPrintingWithDocumentName:(NSString *)documentName {
   [[self renderingContext] beginPrintingWithDocumentName:documentName];
}

-(void)endPrinting {
   [[self renderingContext] endPrinting];
}

-(BOOL)getImageableRect:(NSRect *)rect {
   KGDeviceContext_gdi *deviceContext=[[self renderingContext] deviceContext];
   if(deviceContext==nil)
    return NO;
    
   *rect=[deviceContext imageableRect];
   return YES;
}

-(void)drawContext:(KGContext *)other inRect:(CGRect)rect {
   if(![other isKindOfClass:[KGContext_gdi class]])
    return;
   
   CGAffineTransform ctm;
   
   [self getCTM:&ctm];
      
   [[self renderingContext] drawOther:[(KGContext_gdi *)other renderingContext] inRect:rect ctm:ctm];
 }

-(void)copyContext:(KGContext *)other size:(NSSize)size {
   if(![other isKindOfClass:[KGContext_gdi class]])
    return;

   [[self renderingContext] drawOther:[(KGContext_gdi *)other renderingContext] inRect:NSMakeRect(0,0,size.width,size.height) ctm:CGAffineTransformIdentity];
}

-(void)flush {
   GdiFlush();
}

-(NSData *)captureBitmapInRect:(NSRect)rect {
   return [[self renderingContext] captureBitmapInRect:rect ctm:[self currentState]->_ctm];
}

@end
