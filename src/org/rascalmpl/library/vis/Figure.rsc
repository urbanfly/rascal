@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Paul Klint - Paul.Klint@cwi.nl - CWI}
module vis::Figure

import vis::KeySym;
import Integer;
import Real;
import List;
import Set;
import IO;
import String;
import ToString;

/*
 * Declarations and library functions for Rascal Visualization
 *
 * There are several sources of ugliness in the following definitions:
 * - data declarations cannot have varyadic parameters, hence we need a wrapper function for each constructor.
 * - Alternatives of a data declaration always need a constructor, hence many constructors have to be duplicated.
 * - We are awaiting the intro of key word parameters.
 */
 
/*
 * Wishlist:
 * - textures
 * - boxes with round corners
 * - drop shadows
 * - dashed/dotted lines
 * - ngons
 * - bitmap import and display
 * - new layouts (circular) treemap, icecle
 * - interaction
 */
 
 /*
  * Colors and color management
  */

alias Color = int;

/*
 * Decorations for source code lines:
 * - info, warning and error
 * - highlights (levels [0 .. 4] currently supported)
 * Used by:
 * - Outline
 * - editor
 */

public data LineDecoration = 
    info(int lineNumber, str msg)
  | warning(int lineNumber, str msg)
  | error(int lineNumber, str msg)
  | highlight(int lineNumber, str msg)
  | highlight(int lineNumber, str msg, int level)
  ;

@doc{Gray color (0-255)}
@javaClass{org.rascalmpl.library.vis.util.FigureColorUtils}
public java Color gray(int gray);

@doc{Gray color (0-255) with transparency}
@javaClass{org.rascalmpl.library.vis.util.FigureColorUtils}
public java Color gray(int gray, real alpha);

@doc{Gray color as percentage (0.0-1.0)}
@javaClass{org.rascalmpl.library.vis.util.FigureColorUtils}
public java Color gray(real perc);

@doc{Gray color with transparency}
@javaClass{org.rascalmpl.library.vis.util.FigureColorUtils}
public java Color gray(real perc, real alpha);

@doc{Named color}
@reflect{Needs calling context when generating an exception}
@javaClass{org.rascalmpl.library.vis.util.FigureColorUtils}
public java Color color(str colorName);

@doc{Named color with transparency}
@reflect{Needs calling context when generating an exception}
@javaClass{org.rascalmpl.library.vis.util.FigureColorUtils}
public java Color color(str colorName, real alpha);

@doc{Sorted list of all color names}
@javaClass{org.rascalmpl.library.vis.util.FigureColorUtils}
public java list[str] colorNames();

@doc{RGB color}
@javaClass{org.rascalmpl.library.vis.util.FigureColorUtils}
public java Color rgb(int r, int g, int b);

@doc{RGB color with transparency}
@javaClass{org.rascalmpl.library.vis.util.FigureColorUtils}
public java Color rgb(int r, int g, int b, real alpha);

@doc{Interpolate two colors (in RGB space)}
@javaClass{org.rascalmpl.library.vis.util.FigureColorUtils}
public java Color interpolateColor(Color from, Color to, real percentage);

@doc{Create a list of interpolated colors}
@javaClass{org.rascalmpl.library.vis.util.FigureColorUtils}
public java list[Color] colorSteps(Color from, Color to, int steps);

@doc{Create a colorscale from a list of numbers}
public Color(&T <: num) colorScale(list[&T <: num] values, Color from, Color to){
   mn = min(values);
   range = max(values) - mn;
   sc = colorSteps(from, to, 10);
   return Color(int v) { return sc[(9 * (v - mn)) / range]; };
}

@doc{Create a fixed color palette}
public list[str] p12 = [ "yellow", "aqua", "navy", "violet", 
                          "red", "darkviolet", "maroon", "green",
                          "teal", "blue", "olive", "lime"];
                          
public list[Color] p12Colors = [color(s) | s <- p12];

@doc{Return named color from fixed palette}
public str palette(int n){
  try 
  	return p12[n];
  catch:
    return "black";
}

/*
@doc{Create a list of font names}
@javaClass{org.rascalmpl.library.vis.FigureLibrary}
public java list[str] fontNames();
*/

/*
 * FProperty -- visual properties of visual elements
 */
 
 public FProperty left(){
   return halign(0.0);
 }
 
 public FProperty hcenter(){
   return halign(0.5);
 }
 
 public FProperty right(){
   return halign(1.0);
 }
 
 public FProperty top(){
   return valign(0.0);
 }
 
 public FProperty vcenter(){
   return valign(0.5);
 }
 
 public FProperty bottom(){
   return valign(1.0);
 }
 
 public FProperty center(){
   return align(0.5, 0.5);
}


 public FProperty stdLeft(){
   return stdHalign(0.0);
 }
 
 public FProperty stdHcenter(){
   return stdHalign(0.5);
 }
 
 public FProperty stdRight(){
   return stdHalign(1.0);
 }
 
 public FProperty stdTop(){
   return stdValign(0.0);
 }
 
 public FProperty stdVcenter(){
   return stdValign(0.5);
 }
 
 public FProperty stdBottom(){
   return stdValign(1.0);
 }
 
 public FProperty stdCenter(){
   return stdAlign(0.5, 0.5);
}


 public FProperty projectLeft(){
   return projectHalign(0.0);
 }
 
 public FProperty projectHcenter(){
   return projectHalign(0.5);
 }
 
 public FProperty projectRight(){
   return projectHalign(1.0);
 }
 
 public FProperty projectTop(){
   return projectValign(0.0);
 }
 
 public FProperty projectVcenter(){
   return projectValign(0.5);
 }
 
 public FProperty projectBottom(){
   return projectValign(1.0);
 }
 
 public FProperty projectCenter(){
   return projectValign(0.5, 0.5);
}


data Like = like(str id);
public data Measure = measure(num quantity,str axisId);

public alias FProperties = list[FProperty];
 
 alias computedBool = bool();
 alias computedInt	= int();
 alias computedReal = real();
 alias computedNum 	= num();
 alias computedStr 	= str();
 alias computedColor = Color();
 alias computedFigure = Figure();

data PropertyValue[&T] = constant(&T val)
						| computed(&T () cval)
						| measure(Measure m);

data Convert = convert(value v, value id);

data FProperty =
	mouseOver(Figure fig)
	|std(FProperty property)
	|timer                (int delay, int () cbb)
	|project              (Figure f0, str p0)
	|_child               (FProperties props)
	|unpack(FProperties props)
	// begin generated code
	|shapeClosed(bool     b  )
	|shapeClosed(bool()   cb )
	|shapeClosed(Measure  mv )
	|shapeConnected(bool     b  )
	|shapeConnected(bool()   cb )
	|shapeConnected(Measure  mv )
	|shapeCurved(bool     b  )
	|shapeCurved(bool()   cb )
	|shapeCurved(Measure  mv )
	|hstartGap  (bool     b  )
	|hstartGap  (bool()   cb )
	|hstartGap  (Measure  mv )
	|hendGap    (bool     b  )
	|hendGap    (bool()   cb )
	|hendGap    (Measure  mv )
	|vstartGap  (bool     b  )
	|vstartGap  (bool()   cb )
	|vstartGap  (Measure  mv )
	|vendGap    (bool     b  )
	|vendGap    (bool()   cb )
	|vendGap    (Measure  mv )
	|hresizable (bool     b  )
	|hresizable (bool()   cb )
	|hresizable (Measure  mv )
	|vresizable (bool     b  )
	|vresizable (bool()   cb )
	|vresizable (Measure  mv )
	|hzoomable  (bool     b  )
	|hzoomable  (bool()   cb )
	|hzoomable  (Measure  mv )
	|vzoomable  (bool     b  )
	|vzoomable  (bool()   cb )
	|vzoomable  (Measure  mv )
	|allAngles  (bool     b  )
	|allAngles  (bool()   cb )
	|allAngles  (Measure  mv )
	|shadow     (bool     b  )
	|shadow     (bool()   cb )
	|shadow     (Measure  mv )
	|fillColor  (Color    c  )
	|fillColor  (Color()  cc )
	|fillColor  (Measure  mv )
	|fillColor  (str      ds )
	|fontColor  (Color    c  )
	|fontColor  (Color()  cc )
	|fontColor  (Measure  mv )
	|fontColor  (str      ds )
	|lineColor  (Color    c  )
	|lineColor  (Color()  cc )
	|lineColor  (Measure  mv )
	|lineColor  (str      ds )
	|guideColor (Color    c  )
	|guideColor (Color()  cc )
	|guideColor (Measure  mv )
	|guideColor (str      ds )
	|shadowColor(Color    c  )
	|shadowColor(Color()  cc )
	|shadowColor(Measure  mv )
	|shadowColor(str      ds )
	|aspectRatio(real     r  )
	|aspectRatio(real()   cr )
	|aspectRatio(Measure  mv )
	|ialign     (real     r  )
	|ialign     (real()   cr )
	|ialign     (Measure  mv )
	|width      (real     r  )
	|width      (real()   cr )
	|width      (Measure  mv )
	|height     (real     r  )
	|height     (real()   cr )
	|height     (Measure  mv )
	|hgap       (real     r  )
	|hgap       (real()   cr )
	|hgap       (Measure  mv )
	|vgap       (real     r  )
	|vgap       (real()   cr )
	|vgap       (Measure  mv )
	|hshadowPos (real     r  )
	|hshadowPos (real()   cr )
	|hshadowPos (Measure  mv )
	|vshadowPos (real     r  )
	|vshadowPos (real()   cr )
	|vshadowPos (Measure  mv )
	|hshrink    (real     r  )
	|hshrink    (real()   cr )
	|hshrink    (Measure  mv )
	|vshrink    (real     r  )
	|vshrink    (real()   cr )
	|vshrink    (Measure  mv )
	|halign     (real     r  )
	|halign     (real()   cr )
	|halign     (Measure  mv )
	|valign     (real     r  )
	|valign     (real()   cr )
	|valign     (Measure  mv )
	|hpos       (real     r  )
	|hpos       (real()   cr )
	|hpos       (Measure  mv )
	|vpos       (real     r  )
	|vpos       (real()   cr )
	|vpos       (Measure  mv )
	|hgrow      (real     r  )
	|hgrow      (real()   cr )
	|hgrow      (Measure  mv )
	|vgrow      (real     r  )
	|vgrow      (real()   cr )
	|vgrow      (Measure  mv )
	|lineWidth  (real     r  )
	|lineWidth  (real()   cr )
	|lineWidth  (Measure  mv )
	|toArrow    (Figure   f  )
	|toArrow    (Figure() cf )
	|toArrow    (Measure  mv )
	|fromArrow  (Figure   f  )
	|fromArrow  (Figure() cf )
	|fromArrow  (Measure  mv )
	|label      (Figure   f  )
	|label      (Figure() cf )
	|label      (Measure  mv )
	|fontSize   (int      i  )
	|fontSize   (int()    ci )
	|fontSize   (Measure  mv )
	|lineStyle  (str      s  )
	|lineStyle  (str()    cs )
	|lineStyle  (Measure  mv )
	|hint       (str      s  )
	|hint       (str()    cs )
	|hint       (Measure  mv )
	|id         (str      s  )
	|id         (str()    cs )
	|id         (Measure  mv )
	|font       (str      s  )
	|font       (str()    cs )
	|font       (Measure  mv )
	|onClick    (bool ()  h0 )
	|onMouseMove(void (bool) h1 )
	|onKey      (bool (KeySym, bool, map[KeyModifier,bool]) h2 )
;

public FProperty resizable  (bool     b  ){ return unpack([hresizable (b  ),vresizable (b  )]); }
public FProperty resizable  (bool()   cb ){ return unpack([hresizable (cb ),vresizable (cb )]); }
public FProperty resizable  (Measure  mv ){ return unpack([hresizable (mv ),vresizable (mv )]); }
public FProperty zoomable   (bool     b  ){ return unpack([hzoomable  (b  ),vzoomable  (b  )]); }
public FProperty zoomable   (bool()   cb ){ return unpack([hzoomable  (cb ),vzoomable  (cb )]); }
public FProperty zoomable   (Measure  mv ){ return unpack([hzoomable  (mv ),vzoomable  (mv )]); }
public FProperty startGap   (bool     b  ){ return unpack([hstartGap  (b  ),vstartGap  (b  )]); }
public FProperty startGap   (bool()   cb ){ return unpack([hstartGap  (cb ),vstartGap  (cb )]); }
public FProperty startGap   (Measure  mv ){ return unpack([hstartGap  (mv ),vstartGap  (mv )]); }
public FProperty endGap     (bool     b  ){ return unpack([hendGap    (b  ),vendGap    (b  )]); }
public FProperty endGap     (bool()   cb ){ return unpack([hendGap    (cb ),vendGap    (cb )]); }
public FProperty endGap     (Measure  mv ){ return unpack([hendGap    (mv ),vendGap    (mv )]); }
public FProperty pos        (real     r  ){ return unpack([hpos       (r  ),vpos       (r  )]); }
public FProperty pos        (real()   cr ){ return unpack([hpos       (cr ),vpos       (cr )]); }
public FProperty pos        (Measure  mv ){ return unpack([hpos       (mv ),vpos       (mv )]); }
public FProperty size       (real     r  ){ return unpack([width      (r  ),height     (r  )]); }
public FProperty size       (real()   cr ){ return unpack([width      (cr ),height     (cr )]); }
public FProperty size       (Measure  mv ){ return unpack([width      (mv ),height     (mv )]); }
public FProperty gap        (real     r  ){ return unpack([hgap       (r  ),vgap       (r  )]); }
public FProperty gap        (real()   cr ){ return unpack([hgap       (cr ),vgap       (cr )]); }
public FProperty gap        (Measure  mv ){ return unpack([hgap       (mv ),vgap       (mv )]); }
public FProperty shadowPos  (real     r  ){ return unpack([hshadowPos (r  ),vshadowPos (r  )]); }
public FProperty shadowPos  (real()   cr ){ return unpack([hshadowPos (cr ),vshadowPos (cr )]); }
public FProperty shadowPos  (Measure  mv ){ return unpack([hshadowPos (mv ),vshadowPos (mv )]); }
public FProperty shrink     (real     r  ){ return unpack([hshrink    (r  ),vshrink    (r  )]); }
public FProperty shrink     (real()   cr ){ return unpack([hshrink    (cr ),vshrink    (cr )]); }
public FProperty shrink     (Measure  mv ){ return unpack([hshrink    (mv ),vshrink    (mv )]); }
public FProperty align      (real     r  ){ return unpack([halign     (r  ),valign     (r  )]); }
public FProperty align      (real()   cr ){ return unpack([halign     (cr ),valign     (cr )]); }
public FProperty align      (Measure  mv ){ return unpack([halign     (mv ),valign     (mv )]); }
public FProperty grow       (real     r  ){ return unpack([hgrow      (r  ),vgrow      (r  )]); }
public FProperty grow       (real()   cr ){ return unpack([hgrow      (cr ),vgrow      (cr )]); }
public FProperty grow       (Measure  mv ){ return unpack([hgrow      (mv ),vgrow      (mv )]); }
public FProperty resizable  (bool     b00  ,bool     b200 ){ return unpack([hresizable (b00  ),vresizable (b200 )]); }
public FProperty resizable  (bool     b01  ,bool()   cb201){ return unpack([hresizable (b01  ),vresizable (cb201)]); }
public FProperty resizable  (bool     b02  ,Measure  mv202){ return unpack([hresizable (b02  ),vresizable (mv202)]); }
public FProperty resizable  (bool()   cb10 ,bool     b210 ){ return unpack([hresizable (cb10 ),vresizable (b210 )]); }
public FProperty resizable  (bool()   cb11 ,bool()   cb211){ return unpack([hresizable (cb11 ),vresizable (cb211)]); }
public FProperty resizable  (bool()   cb12 ,Measure  mv212){ return unpack([hresizable (cb12 ),vresizable (mv212)]); }
public FProperty resizable  (Measure  mv20 ,bool     b220 ){ return unpack([hresizable (mv20 ),vresizable (b220 )]); }
public FProperty resizable  (Measure  mv21 ,bool()   cb221){ return unpack([hresizable (mv21 ),vresizable (cb221)]); }
public FProperty resizable  (Measure  mv22 ,Measure  mv222){ return unpack([hresizable (mv22 ),vresizable (mv222)]); }
public FProperty zoomable   (bool     b00  ,bool     b200 ){ return unpack([hzoomable  (b00  ),vzoomable  (b200 )]); }
public FProperty zoomable   (bool     b01  ,bool()   cb201){ return unpack([hzoomable  (b01  ),vzoomable  (cb201)]); }
public FProperty zoomable   (bool     b02  ,Measure  mv202){ return unpack([hzoomable  (b02  ),vzoomable  (mv202)]); }
public FProperty zoomable   (bool()   cb10 ,bool     b210 ){ return unpack([hzoomable  (cb10 ),vzoomable  (b210 )]); }
public FProperty zoomable   (bool()   cb11 ,bool()   cb211){ return unpack([hzoomable  (cb11 ),vzoomable  (cb211)]); }
public FProperty zoomable   (bool()   cb12 ,Measure  mv212){ return unpack([hzoomable  (cb12 ),vzoomable  (mv212)]); }
public FProperty zoomable   (Measure  mv20 ,bool     b220 ){ return unpack([hzoomable  (mv20 ),vzoomable  (b220 )]); }
public FProperty zoomable   (Measure  mv21 ,bool()   cb221){ return unpack([hzoomable  (mv21 ),vzoomable  (cb221)]); }
public FProperty zoomable   (Measure  mv22 ,Measure  mv222){ return unpack([hzoomable  (mv22 ),vzoomable  (mv222)]); }
public FProperty startGap   (bool     b00  ,bool     b200 ){ return unpack([hstartGap  (b00  ),vstartGap  (b200 )]); }
public FProperty startGap   (bool     b01  ,bool()   cb201){ return unpack([hstartGap  (b01  ),vstartGap  (cb201)]); }
public FProperty startGap   (bool     b02  ,Measure  mv202){ return unpack([hstartGap  (b02  ),vstartGap  (mv202)]); }
public FProperty startGap   (bool()   cb10 ,bool     b210 ){ return unpack([hstartGap  (cb10 ),vstartGap  (b210 )]); }
public FProperty startGap   (bool()   cb11 ,bool()   cb211){ return unpack([hstartGap  (cb11 ),vstartGap  (cb211)]); }
public FProperty startGap   (bool()   cb12 ,Measure  mv212){ return unpack([hstartGap  (cb12 ),vstartGap  (mv212)]); }
public FProperty startGap   (Measure  mv20 ,bool     b220 ){ return unpack([hstartGap  (mv20 ),vstartGap  (b220 )]); }
public FProperty startGap   (Measure  mv21 ,bool()   cb221){ return unpack([hstartGap  (mv21 ),vstartGap  (cb221)]); }
public FProperty startGap   (Measure  mv22 ,Measure  mv222){ return unpack([hstartGap  (mv22 ),vstartGap  (mv222)]); }
public FProperty endGap     (bool     b00  ,bool     b200 ){ return unpack([hendGap    (b00  ),vendGap    (b200 )]); }
public FProperty endGap     (bool     b01  ,bool()   cb201){ return unpack([hendGap    (b01  ),vendGap    (cb201)]); }
public FProperty endGap     (bool     b02  ,Measure  mv202){ return unpack([hendGap    (b02  ),vendGap    (mv202)]); }
public FProperty endGap     (bool()   cb10 ,bool     b210 ){ return unpack([hendGap    (cb10 ),vendGap    (b210 )]); }
public FProperty endGap     (bool()   cb11 ,bool()   cb211){ return unpack([hendGap    (cb11 ),vendGap    (cb211)]); }
public FProperty endGap     (bool()   cb12 ,Measure  mv212){ return unpack([hendGap    (cb12 ),vendGap    (mv212)]); }
public FProperty endGap     (Measure  mv20 ,bool     b220 ){ return unpack([hendGap    (mv20 ),vendGap    (b220 )]); }
public FProperty endGap     (Measure  mv21 ,bool()   cb221){ return unpack([hendGap    (mv21 ),vendGap    (cb221)]); }
public FProperty endGap     (Measure  mv22 ,Measure  mv222){ return unpack([hendGap    (mv22 ),vendGap    (mv222)]); }
public FProperty pos        (real     r00  ,real     r200 ){ return unpack([hpos       (r00  ),vpos       (r200 )]); }
public FProperty pos        (real     r01  ,real()   cr201){ return unpack([hpos       (r01  ),vpos       (cr201)]); }
public FProperty pos        (real     r02  ,Measure  mv202){ return unpack([hpos       (r02  ),vpos       (mv202)]); }
public FProperty pos        (real()   cr10 ,real     r210 ){ return unpack([hpos       (cr10 ),vpos       (r210 )]); }
public FProperty pos        (real()   cr11 ,real()   cr211){ return unpack([hpos       (cr11 ),vpos       (cr211)]); }
public FProperty pos        (real()   cr12 ,Measure  mv212){ return unpack([hpos       (cr12 ),vpos       (mv212)]); }
public FProperty pos        (Measure  mv20 ,real     r220 ){ return unpack([hpos       (mv20 ),vpos       (r220 )]); }
public FProperty pos        (Measure  mv21 ,real()   cr221){ return unpack([hpos       (mv21 ),vpos       (cr221)]); }
public FProperty pos        (Measure  mv22 ,Measure  mv222){ return unpack([hpos       (mv22 ),vpos       (mv222)]); }
public FProperty size       (real     r00  ,real     r200 ){ return unpack([width      (r00  ),height     (r200 )]); }
public FProperty size       (real     r01  ,real()   cr201){ return unpack([width      (r01  ),height     (cr201)]); }
public FProperty size       (real     r02  ,Measure  mv202){ return unpack([width      (r02  ),height     (mv202)]); }
public FProperty size       (real()   cr10 ,real     r210 ){ return unpack([width      (cr10 ),height     (r210 )]); }
public FProperty size       (real()   cr11 ,real()   cr211){ return unpack([width      (cr11 ),height     (cr211)]); }
public FProperty size       (real()   cr12 ,Measure  mv212){ return unpack([width      (cr12 ),height     (mv212)]); }
public FProperty size       (Measure  mv20 ,real     r220 ){ return unpack([width      (mv20 ),height     (r220 )]); }
public FProperty size       (Measure  mv21 ,real()   cr221){ return unpack([width      (mv21 ),height     (cr221)]); }
public FProperty size       (Measure  mv22 ,Measure  mv222){ return unpack([width      (mv22 ),height     (mv222)]); }
public FProperty gap        (real     r00  ,real     r200 ){ return unpack([hgap       (r00  ),vgap       (r200 )]); }
public FProperty gap        (real     r01  ,real()   cr201){ return unpack([hgap       (r01  ),vgap       (cr201)]); }
public FProperty gap        (real     r02  ,Measure  mv202){ return unpack([hgap       (r02  ),vgap       (mv202)]); }
public FProperty gap        (real()   cr10 ,real     r210 ){ return unpack([hgap       (cr10 ),vgap       (r210 )]); }
public FProperty gap        (real()   cr11 ,real()   cr211){ return unpack([hgap       (cr11 ),vgap       (cr211)]); }
public FProperty gap        (real()   cr12 ,Measure  mv212){ return unpack([hgap       (cr12 ),vgap       (mv212)]); }
public FProperty gap        (Measure  mv20 ,real     r220 ){ return unpack([hgap       (mv20 ),vgap       (r220 )]); }
public FProperty gap        (Measure  mv21 ,real()   cr221){ return unpack([hgap       (mv21 ),vgap       (cr221)]); }
public FProperty gap        (Measure  mv22 ,Measure  mv222){ return unpack([hgap       (mv22 ),vgap       (mv222)]); }
public FProperty shadowPos  (real     r00  ,real     r200 ){ return unpack([hshadowPos (r00  ),vshadowPos (r200 )]); }
public FProperty shadowPos  (real     r01  ,real()   cr201){ return unpack([hshadowPos (r01  ),vshadowPos (cr201)]); }
public FProperty shadowPos  (real     r02  ,Measure  mv202){ return unpack([hshadowPos (r02  ),vshadowPos (mv202)]); }
public FProperty shadowPos  (real()   cr10 ,real     r210 ){ return unpack([hshadowPos (cr10 ),vshadowPos (r210 )]); }
public FProperty shadowPos  (real()   cr11 ,real()   cr211){ return unpack([hshadowPos (cr11 ),vshadowPos (cr211)]); }
public FProperty shadowPos  (real()   cr12 ,Measure  mv212){ return unpack([hshadowPos (cr12 ),vshadowPos (mv212)]); }
public FProperty shadowPos  (Measure  mv20 ,real     r220 ){ return unpack([hshadowPos (mv20 ),vshadowPos (r220 )]); }
public FProperty shadowPos  (Measure  mv21 ,real()   cr221){ return unpack([hshadowPos (mv21 ),vshadowPos (cr221)]); }
public FProperty shadowPos  (Measure  mv22 ,Measure  mv222){ return unpack([hshadowPos (mv22 ),vshadowPos (mv222)]); }
public FProperty shrink     (real     r00  ,real     r200 ){ return unpack([hshrink    (r00  ),vshrink    (r200 )]); }
public FProperty shrink     (real     r01  ,real()   cr201){ return unpack([hshrink    (r01  ),vshrink    (cr201)]); }
public FProperty shrink     (real     r02  ,Measure  mv202){ return unpack([hshrink    (r02  ),vshrink    (mv202)]); }
public FProperty shrink     (real()   cr10 ,real     r210 ){ return unpack([hshrink    (cr10 ),vshrink    (r210 )]); }
public FProperty shrink     (real()   cr11 ,real()   cr211){ return unpack([hshrink    (cr11 ),vshrink    (cr211)]); }
public FProperty shrink     (real()   cr12 ,Measure  mv212){ return unpack([hshrink    (cr12 ),vshrink    (mv212)]); }
public FProperty shrink     (Measure  mv20 ,real     r220 ){ return unpack([hshrink    (mv20 ),vshrink    (r220 )]); }
public FProperty shrink     (Measure  mv21 ,real()   cr221){ return unpack([hshrink    (mv21 ),vshrink    (cr221)]); }
public FProperty shrink     (Measure  mv22 ,Measure  mv222){ return unpack([hshrink    (mv22 ),vshrink    (mv222)]); }
public FProperty align      (real     r00  ,real     r200 ){ return unpack([halign     (r00  ),valign     (r200 )]); }
public FProperty align      (real     r01  ,real()   cr201){ return unpack([halign     (r01  ),valign     (cr201)]); }
public FProperty align      (real     r02  ,Measure  mv202){ return unpack([halign     (r02  ),valign     (mv202)]); }
public FProperty align      (real()   cr10 ,real     r210 ){ return unpack([halign     (cr10 ),valign     (r210 )]); }
public FProperty align      (real()   cr11 ,real()   cr211){ return unpack([halign     (cr11 ),valign     (cr211)]); }
public FProperty align      (real()   cr12 ,Measure  mv212){ return unpack([halign     (cr12 ),valign     (mv212)]); }
public FProperty align      (Measure  mv20 ,real     r220 ){ return unpack([halign     (mv20 ),valign     (r220 )]); }
public FProperty align      (Measure  mv21 ,real()   cr221){ return unpack([halign     (mv21 ),valign     (cr221)]); }
public FProperty align      (Measure  mv22 ,Measure  mv222){ return unpack([halign     (mv22 ),valign     (mv222)]); }
public FProperty grow       (real     r00  ,real     r200 ){ return unpack([hgrow      (r00  ),vgrow      (r200 )]); }
public FProperty grow       (real     r01  ,real()   cr201){ return unpack([hgrow      (r01  ),vgrow      (cr201)]); }
public FProperty grow       (real     r02  ,Measure  mv202){ return unpack([hgrow      (r02  ),vgrow      (mv202)]); }
public FProperty grow       (real()   cr10 ,real     r210 ){ return unpack([hgrow      (cr10 ),vgrow      (r210 )]); }
public FProperty grow       (real()   cr11 ,real()   cr211){ return unpack([hgrow      (cr11 ),vgrow      (cr211)]); }
public FProperty grow       (real()   cr12 ,Measure  mv212){ return unpack([hgrow      (cr12 ),vgrow      (mv212)]); }
public FProperty grow       (Measure  mv20 ,real     r220 ){ return unpack([hgrow      (mv20 ),vgrow      (r220 )]); }
public FProperty grow       (Measure  mv21 ,real()   cr221){ return unpack([hgrow      (mv21 ),vgrow      (cr221)]); }
public FProperty grow       (Measure  mv22 ,Measure  mv222){ return unpack([hgrow      (mv22 ),vgrow      (mv222)]); }

// end generated code

public FProperty child(FProperty props ...){
	throw "child is currently out of order (broken)";
	return _child(props);
}

public FProperty grandChild(FProperty props ...){
	return _child([_child(props)]);
}



data Edge =			 							// edge between between two elements in complex shapes like tree or graph
     _edge(str from, str to, FProperties prop)
 //  | _edge(str from, str to, Figure toArrow, FProperties prop)
 //  | _edge(str from, str to, Figure toArrow, Figure fromArrow, FProperties prop)
   ;
   
public alias Edges = list[Edge];
   
public Edge edge(str from, str to, FProperty props ...){
  return _edge(from, to, props);
}

public Edge edge(str from, str to, Figure toArrowP, FProperty props ...){
  return _edge(from, to, [toArrow(toArrowP)] + props);
}
public Edge edge(str from, str to, Figure fromArrowP, Figure toArrowP,  FProperty props ...){
  return _edge(from, to, [toArrow(toArrowP),fromArrow(fromArrowP)] + props);
}



/*
 * Figure: a visual element, the principal visualization datatype
 */
 
public alias Figures = list[Figure];
 
public data Figure = 
/* atomic primitives */
	
     _text(str s, FProperties props)		    // text label
   | _text(computedStr sv, FProperties props)
   
   												// file outline
   | _outline(list[LineDecoration] lineInfo, int maxLine, FProperties props)
   
   
/* primitives/containers */
   | _widthDepsHeight(Figure inner, FProperties props)
   | _box(FProperties props)			          // rectangular box
   | _box(Figure inner, FProperties props)       // rectangular box with inner element
   
   | _ellipse(FProperties props)                 // ellipse with inner element
   | _ellipse(Figure inner, FProperties props)   // ellipse with inner element
   
   | _wedge(FProperties props)			      	// wedge
   | _wedge(Figure inner, FProperties props)     // wedge with inner element
   
   | _space(FProperties props)			      	// invisible box (used for spacing)
   | _space(Figure inner, FProperties props)     // invisible box with visible inner element   
   | _leftScreen(Figure inner, FProperties props) // a screen on which things can be projected   
   | _rightScreen(Figure inner, FProperties props) // a screen on which things can be projected   
   | _topScreen(Figure inner, FProperties props) // a screen on which things can be projected   
   | _bottomScreen(Figure inner, FProperties props) // a screen on which things can be projected   

   
   | _leftAxis(str name,Figure inner, FProperties props)
   | _rightAxis(str name,Figure inner, FProperties props) 
   | _topAxis(str name,Figure inner, FProperties props)
   | _bottomAxis(str name,Figure inner, FProperties props)

   
   
   | _vscreen(FProperties props)                  // a screen on which things can be projected      
   | _vscreen(Figure inner, FProperties props)
   
   | _projection(Figure fig, str id, Figure project,FProperties props)   // project from the location of fig to the screen id 
   
   | _scrollable(bool hscroll,bool vscroll,Figure fig, FProperties props)
        
   | _timer(int delay,int () callBack, Figure inner,FProperties props)

/* composition */
   | _withDependantWidthHeight(bool widthMajor,Figure innder, FProperties props)
   | _mouseOver(Figure under, Figure over, FProperties props)
   | _fswitch(int () choice,Figures figs, FProperties props)
   | _overlap(Figure under, Figure over, FProperties props)
   | _mouseOver(Figure under,Figure over,FProperties props)          
                   
   | _hvcat(Figures figs, FProperties props) // horizontal and vertical concatenation
                   
   | _overlay(Figures figs, FProperties props)// overlay (stacked) composition
   

   | _grid(list[list[Figure]] figMatrix, FProperties props)
   
  								                // composition by 2D packing
   | _pack(Figures figs, FProperties props)
   
  												 // composition of nodes and edges as graph
   | _graph(Figures nodes, Edges edges, FProperties props)
   
                							    // composition of nodes and edges as tree
   | _tree(Figures nodes, Edges edges, FProperties props)
   
   | _treemap(Figures nodes, Edges edges, FProperties props)
   
   | _nominalKey(list[value] possibilities, Figure (list[value]) whole,FProperties props)
   
   | _intervalKey(value (real part) interpolate, Figure (value low, value high) explain,FProperties props)
   
/* transformation */

   | _rotate(num angle, Figure fig, FProperties props)			    // Rotate element around its anchor point
   | _scale(num perc, Figure fig, FProperties props)	   		    // Scale element (same for h and v)
   | _scale(num xperc, num yperc, Figure fig, FProperties props)	// Scale element (different for h and v)

/* interaction */

   | _computeFigure(Figure () computeFig, FProperties props)
   | _button(str label, void () vcallback, FProperties props)
   | _textfield(str text, void (str) scallback, FProperties props)
   | _textfield(str text, void (str) scallback, bool (str) validate, FProperties props)
   | _combo(list[str] choices, void (str) scallback, FProperties props)
   | _choice(list[str] choices, void(str s) ccallback, FProperties props)
   | _checkbox(str text, bool checked, void(bool) vbcallback, FProperties props)
   ;

public Figure text(str s, FProperty props ...){
  return _text(s, props);
}

public Figure text(computedStr sv, FProperty props ...){
  return _text(sv, props);
}

public Figure outline (list[LineDecoration] lineInfo, int maxLine, FProperty props ...){
  return _outline(lineInfo, maxLine, props);
}

public Figure box(FProperty props ...){
  return _box(props);
}

public Figure box(Figure fig, FProperty props ...){
  return _box(fig, props);
}

public Figure ellipse(FProperty props ...){
  return _ellipse(props);
}

public Figure ellipse(Figure fig, FProperty props ...){
  return _ellipse(fig, props);
}

public Figure wedge(FProperty props ...){
  return _wedge(props);
}

public Figure wedge(Figure fig, FProperty props ...){
  return _wedge(fig, props);
}  

public Figure space(FProperty props ...){
  return _space(props);
}

public Figure space(Figure fig, FProperty props ...){
  return _space(fig, props);
}

public Figure haxis(Figure fig, FProperty props ...){
  return _haxis(fig, props);
}

public Figure vaxis(Figure fig, FProperty props ...){
  return _vaxis(fig, props);
}

public Figure leftScreen(str i,Figure fig, FProperty props ...){
  return _leftScreen(fig,[id(i)] + props);
}

public Figure rightScreen(str i,Figure fig, FProperty props ...){
  return _rightScreen(fig, [id(i)] + props);
}

public Figure topScreen(str i,Figure fig, FProperty props ...){
  return _topScreen(fig, [id(i)] +props);
}

public Figure bottomScreen(str i,Figure fig, FProperty props ...){
  return _bottomScreen(fig, [id(i)] +props);
}


public Figure leftAxis(str name,str i,Figure fig, FProperty props ...){
  return _leftAxis(name,fig, [id(i)] + props);
}

public Figure rightAxis(str name,str i,Figure fig, FProperty props ...){
  return _rightAxis(name,fig, [id(i)] + props);
}

public Figure topAxis(str name,str i,Figure fig, FProperty props ...){
  return _topAxis(name,fig, [id(i)] + props);
}

public Figure bottomAxis(str name,str i,Figure fig, FProperty props ...){
  return _bottomAxis(name,fig, [id(i)] + props);
}

public Figure leftAxis(str i,Figure fig, FProperty props ...){
  return _leftAxis("",fig, [id(i)] + props);
}

public Figure rightAxis(str i,Figure fig, FProperty props ...){
  return _rightAxis("",fig, [id(i)] + props);
}

public Figure topAxis(str i,Figure fig, FProperty props ...){
  return _topAxis("",fig, [id(i)] + props);
}

public Figure bottomAxis(str i,Figure fig, FProperty props ...){
  return _bottomAxis("",fig, [id(i)] + props);
}

public Figure projection(Figure fig, str id, Figure project,FProperty props ...){
  return _projection(fig,id,project,props);
}

public Figure scrollable(Figure fig, FProperty props...){
	return _scrollable(true,true,fig,props);
}

public Figure hscrollable(Figure fig, FProperty props...){
	return _scrollable(true,false,fig,props);
}

public Figure vscrollable(Figure fig, FProperty props...){
	return _scrollable(false,true,fig,props);
}


public Figure place(Figure fig, str at, Figure base, FProperty props ...){
  return _place(fig, at, base, props);
}

public Figure use(Figure fig, FProperty props ...){
  return _use(fig, props);
}

public Figure overlap(Figure under,Figure over, FProperty props ...){
  return _overlap(under,over,props);
}

public Figure hcat(Figures figs, FProperty props ...){
  return _grid([[figs]],props);
}

public Figure vcat(Figures figs, FProperty props ...){
  newList = for(f <- figs){
  	append [f];
  };
  return _grid(newList, props);
}

public Figure hvcat(Figures figs, FProperty props ...){
  return _widthDepsHeight(_hvcat(figs, props),[]);
}


public Figure fswitch(int () choice,Figures figs, FProperty props ...){
  return _fswitch(choice,figs, props);
}


public Figure overlay(Figures figs, FProperty props ...){
  return _overlay(figs, props);
}


public Figure grid(list[list[Figure]] figs, FProperty props ...){
  return _grid(figs, props);
}

public Figure pack(Figures figs, FProperty props ...){
  return _widthDepsHeight(_pack(figs, props),[]);
}

public Figure graph(Figures nodes, Edges edges, FProperty props...){
  return _graph(nodes, edges, [stdResizable(false)] + props);
}

public Figure tree(Figures nodes, Edges edges, FProperty props...){
  return _tree(nodes, edges, [stdResizable(false)] + props);
}

public Figure treemap(Figures nodes, Edges edges, FProperty props...){
  return _treemap(nodes, edges, props);
}

public Figure rotate(num angle, Figure fig, FProperty props...){
  return _rotate(angle, fig, props);
}

public Figure scale(num perc, Figure fig, FProperty props...){
  return _scale(perc, fig, props);
}

public Figure scale(num xperc, num yperc, Figure fig, FProperty props...){
  return _scale(xperc, yperc, fig, props);
}

public Figure boolControl(str name, Figure figOn, Figure figOff, FProperty props...){
  return _boolControl(name, figOn, figOff, props);
}

public Figure controlOn(str name, Figure fig, FProperty props...){
  return _controlOn(name, fig, props);
}

public Figure controlOff(str name, Figure fig, FProperty props...){
  return _controlOff(name, fig, props);
}

public Figure strControl(str name, str initial, FProperty props...){
  return _strControl(name, initial, props);
}

public Figure intControl(str name, int initial, FProperty props...){
  return _intControl(name, initial, props);
}

public Figure colorControl(str name, int initial, FProperty props...){
  return _colorControl(name, initial, props);
}

public Figure colorControl(str name, str initial, FProperty props...){
  return _colorControl(name, initial, props);
}

public Figure computeFigure(Figure () computeFig, FProperty props...){
 	return _computeFigure(computeFig, props);
}
  
public Figure button(str label, void () callback, FProperty props...){
 	return _button(label, callback, props);
}
 
public Figure textfield(str text, void (str) callback, FProperty props...){
 	return _textfield(text, callback, props);
}
 
public Figure textfield(str text,  void (str) callback, bool (str) validate, FProperty props...){
 	return _textfield(text, callback, validate, props);
}

public Figure combo(list[str] choices, void (str) callback, FProperty props...){
 	return _combo(choices, callback, props);
}
 
public Figure choice(list[str] choices, void(str s) ccallback, FProperty props...){
   return _choice(choices, ccallback, props);
}

public Figure checkbox(str text, bool checked, void(bool) vcallback, FProperty props...){
   return _checkbox(text, checked, vcallback, props);
}  
  
public Figure checkbox(str text, void(bool) vcallback, FProperty props...){
   return _checkbox(text, false, vcallback, props);
}  

public Figure normalize(Figure f){
	f = outermost visit(f){
		case Figure f : {
			if([x*,unpack(y),z*] := f.props){
				f.props = [x,y,z];
				insert f;
			} else {
				fail;
			}
		}
	} 
	f = visit(f){
		case Figure f : {
			if([_*,project(y,z),_*] := f.props){
				projects = [];
				otherProps = [];
				for(elem <- f.props){
					if(project(_,_) := elem){
						projects+=[elem];
					} else {
						otherProps+=[elem];
					}
				}
				insert (f[props = otherProps] | projection(it,i,p) | project(p,i) <- projects);
			} else { fail ; } 
		}
	}
	f = visit(f){
		case Figure f : {
			if([_*,timer(y,z),_*] := f.props){
				projects = [];
				otherProps = [];
				for(elem <- f.props){
					if(timer(_,_) := elem){
						projects+=[elem];
					} else {
						otherProps+=[elem];
					}
				}
				insert (f[props = otherProps] | _timer(p,i,it,[]) | timer(p,i) <- projects);
			} else { fail ; } 
		}
	}
	f = visit(f){
		case Figure f : {
			if([_*,mouseOver(y),_*] := f.props){
				mouseOvers = [];
				otherProps = [];
				for(elem <- f.props){
					if(mouseOver(_) := elem){
						mouseOvers+=[elem];
					} else {
						otherProps+=[elem];
					}
				}
				insert (f[props = otherProps] | _mouseOver(it,p,[]) | mouseOver(p) <- mouseOvers);
			} else { fail ; } 
		}
	}
	return f;
}



public Figure palleteKey (str name, str key,FProperty props...){
 return  _nominalKey(p12,Figure (list[value] orig) { 
 		Figure inner;
 		if(size(orig) == 0) inner = space(); 
 		else inner = grid([[box(fillColor(p12[i])),text(toString(orig[i]),left())] | i <- [0..size(orig)-1]],hgrow(1.2),vgrow(1.1));
 		return vcat([
 		text(name,fontSize(13)),
 		box(
 			inner
 		)
 		],props);},[id(key)] ); 
}

public Figure hPalleteKey (str name, str key,FProperty props...){
 return  _nominalKey(p12,Figure (list[value] orig) { 
 		Figure inner;
 		if(size(orig) == 0) inner = space(); 
 		else inner = hcat([vcat([box(fillColor(p12[i])),text(toString(orig[i]))],hgrow(1.05)) | i <- [0..size(orig)-1]],hgrow(1.05));
 		return box(hcat([
 		text(name,fontSize(13)),
 		inner
 		], hgrow(1.1)),[hgrow(1.05)] + props);},[id(key)] ); 
}

public Figure title(str name, Figure inner,FProperty props...){
	return vcat([box(text(name,fontSize(17))), box(inner,grow(1.1))],props);
}

public Color rrgba(real r, real g, real b, real a){
	return rgb(toInt(r * 255.0),toInt(g * 255.0),toInt(b * 255.0),a);
}

public Color randomColor(){
	return rrgba(arbReal(),arbReal(),arbReal(),1.0);
}

public Color randomColorAlpha(){
	return rrgba(arbReal(),arbReal(),arbReal(),arbReal());
}

public Figure point(FProperty props...){
	return space([resizable(false), size(0.0)] + props);
}


public Figure colorIntervalKey(str name, str key, Color lowc, Color highc, FProperty props...){
	return  _intervalKey( value (real part) { return interpolateColor(lowc,highc,part); },
				Figure (value low,value high) {
 		Figure inner = hcat([vcat([box(fillColor(lowc)),text(toString(low))]),
 							vcat([box(fillColor(highc)),text(toString(high))])]
 						);
 		return box(hcat([
 		text(name,fontSize(13)),
 		inner
 		], hgrow(1.1)),[hgrow(1.05)] + props);},[id(key)] ); 
 }

alias KeyHandler = void (KeySym,map[KeyModifier,bool]);

public Figure triangle(int side,FProperty props...){
  return overlay([point(left(),bottom()),point(top()), point(right(),bottom())], 
  	[shapeConnected(true), shapeClosed(true),  size(side,sqrt(3.0/4.0) * toReal(side)),
  	resizable(false)] + props);
}

public Figure headNormal(FProperty props...) {
  list[tuple[real x, real y]]  tup = [<0.,1.>, <0.5, 0.>, <1., 1.>];
		  return space(overlay([
		point(halign(t.x), valign(t.y))|tuple[real x, real y] t <-tup], 
		  [ shapeConnected(true), shapeClosed(true)]+props), stdSize(10));
}

public Figure headInv(FProperty props...) {
  list[tuple[real x, real y]]  tup = [<0.,0.>, <0.5, 1.>, <1., 0.>];
   return space(overlay([
		point(halign(t.x), valign(t.y))|tuple[real x, real y] t <-tup], 
		  [ shapeConnected(true), shapeClosed(true)]+props),  stdSize(10));
		
}

public  Figure headDot(FProperty props...) {
	return space(ellipse(props),  stdSize(10));
}

public  Figure headBox(FProperty props...) {
	return space(box(props),  stdSize(10));
}

public Figure headDiamond(FProperty props...) {
  list[tuple[real x, real y]]  tup = [<0.,.5>, <.5, 1.>, <1., .5>, <.5, 0.>];
		  return space(overlay([
		point(halign(t.x), valign(t.y))|tuple[real x, real y] t <-tup], 
		  [ shapeConnected(true), shapeClosed(true)]+props),  stdWidth(10), stdHeight(15));
}

public  Figure headBox(FProperty props...) {
	return space(ellipse(props),  stdSize(10));
}

public  Figure shapeEllipse(FProperty props...) {
	return space(ellipse(props), props+stdWidth(40)+stdHeight(30));
}

public  Figure shapeDoubleEllipse(FProperty props...) {
	return space(ellipse(ellipse(props+stdShrink(0.8)), props),  props+stdWidth(40)+stdHeight(30));
}

public  Figure shapeBox(FProperty props...) {
	return space(box(props),props+stdWidth(40)+stdHeight(30));
}

public Figure shapeDiamond(FProperty props...) {
  list[tuple[real x, real y]]  tup = [<0.,.5>, <.5, 1.>, <1., .5>, <.5, 0.>];
		  return space(overlay([
		point(halign(t.x), valign(t.y))|tuple[real x, real y] t <-tup], 
		  props+shapeConnected(true)+shapeClosed(true)),  props+stdWidth(60)+stdHeight(40));
}

public Figure shapeParallelogram(FProperty props...) {
  real delta = 0.30;
  list[tuple[real x, real y]]  tup = [<delta, 0.>, <1., 0.>, <1.-delta, 1.>, <0., 1.>];
		  return space(overlay([
		point(halign(t.x), valign(t.y))|tuple[real x, real y] t <-tup], 
		  props+shapeConnected(true)+shapeClosed(true)),  props+stdWidth(80)+stdHeight(50));
}

public  Figure shapeEllipse(Figure fig, FProperty props...) {
	return overlay([shapeEllipse(props), fig], shapeClosed(true)+props);
}

public  Figure shapeDoubleEllipse(Figure fig,  FProperty props...) {
	return overlay([shapeDoubleEllipse(props), fig], shapeClosed(true)+props);
}

public  Figure shapeBox(Figure fig, FProperty props...) {
	return overlay([shapeBox(props), fig], shapeClosed(true)+props);
}

public  Figure shapeDiamond(Figure fig, FProperty props...) {
	return overlay([shapeDiamond(props), fig], shapeClosed(true)+props);
}

public  Figure shapeParallelogram(Figure fig, FProperty props...) {
	return overlay([shapeParallelogram(props), fig], shapeClosed(true)+props);
}

public Figure ifFig(bool () cond, Figure onTrue, FProperty props...){
	return fswitch(int () { bool b = cond(); return b ? 1 : 0;}, [ space(), onTrue], props);
}


public Figure boolFig(bool () cond, Figure onTrue, Figure onFalse, FProperty props...){
	return fswitch(int () { bool b = cond(); return b ? 1 : 0;}, [ onFalse, onTrue], props);
}

