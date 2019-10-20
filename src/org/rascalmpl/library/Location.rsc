@license{
  Copyright (c) 2019 SWAT.engineering
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Paul Klint - Paul.Klint@swat.engineering - SWAT.engineering}

@doc{
.Synopsis
Library functions for source locations.

.Description

For a description of source locations see link:/Rascal#Values-Location[Location] in the Rascal Language Reference.

The following functions are defined for source locations:
loctoc::[1]

A source location `l` refers to a text fragment in another file or resource. To easy the description we will
talk about "`l`'s text" instead of the text `l` refers to.
}
module Location

import IO;
import List;
import Set;
import Exception;

@doc{
.Synopsis
Check that two locations refer to the same file.
}
bool isSameFile(loc l, loc r)
    = l.top == r.top;
    
@doc{
.Synopsis
Compare two location values lexicographically.

.Description
When the two locations refer to different files, their paths are compared as string.
When they refer to the same file, their offsets are compared when present.

.Pittfalls
This ordering regards the location value itself as opposed to the text it refers to.
}
bool isLexicallyLess(loc l, loc r)
    = isSameFile(l, r) ? (l.offset ? 0) < (r.offset ? 0) : l.top < r.top;



@doc{
.Synopsis
Get the textual content a location refers to.
}
str getContent(loc l)
    = readFile(l);

@doc{
.Synopsis
Is a location textually (strictly) contained in another location?

.Description
Strict containment between two locations `inner` and `outer` holds when


- `outer`'s text begins before `inner`'s text, or
- `outer`'s text ends after `inner`'s text, or
- both.
}

bool isStrictlyContainedIn(loc inner, loc outer)
    = isSameFile(inner, outer) && (  (inner.offset? && inner.offset > 0 && !outer.offset?) 
                                  || inner.offset == outer.offset && inner.offset + inner.length < outer.offset + outer.length
                                  || inner.offset > outer.offset && inner.offset + inner.length <= outer.offset + outer.length
                                  );

@doc{
.Synopsis
Is a location textually contained in another location?

.Description
Containment between two locations `inner` and `outer` holds when


- `inner` and `outer` are equal, or
- `inner` is strictly contained in `outer`.
}

bool isContainedIn(loc inner, loc outer)
    = isSameFile(inner, outer) && ( (inner.offset? && inner.offset > 0 && !outer.offset?) 
                                  || inner.offset >= outer.offset && inner.offset + inner.length <= outer.offset + outer.length
                                  );


@doc{
.Synopsis
Begins a location's text before (but may overlap with) another location's text?
}
bool beginsBefore(loc l, loc r)
    = isSameFile(l, r) && l.offset < r.offset;
    
@doc{
.Synopsis
Begins and ends a location's text before another location's text?

.Description
`isBefore(l, r)` holds when `l`'s text occurs textually before `r`'s text.
}
bool isBefore(loc l, loc r)
    = isSameFile(l, r)  && l.offset + l.length <= r.offset;

@doc{
.Synopsis
Occurs a location's text _immediately_ before another location's text?

.Description
`isImmediatelyBefore(l, r)` holds when `l`'s text occurs textually before, and is adjacent to, `r`'s text.
}
bool isImmediatelyBefore(loc l, loc r)
    = isSameFile(l, r) && l.offset + l.length == r.offset;
 
 @doc{
.Synopsis
Begins a location's text after (but may overlap with) another location's text?

Description
`beginsAfter(l, r)` holds when `l`'s text begins after `r`'s text. No assumption is made about the end of both texts.
In other words, `l`'s text may end before or after the end of `r`'s text.
}
bool beginsAfter(loc l, loc r)
    = isSameFile(l, r) && l.offset > r.offset;
       
@doc{
.Synopsis
Is a location's text completely after another location's text?
}
bool isAfter(loc l, loc r)
    = isBefore(r, l);

@doc{
.Synopsis
Is a location's text _immediately_ after another location's text?
}
bool isImmediatelyAfter(loc l, loc r)
    = isImmediatelyBefore(r, l);

@doc{
.Synopsis
Refer two locations to text that overlaps?
}
bool isOverlapping(loc l, loc r)
    = isSameFile(l, r) && (  (l.offset <= r.offset && l.offset + l.length > r.offset) 
                          || (r.offset <= l.offset && r.offset + r.length > l.offset)
                          );

@doc{
.Synopsis
Compute a location that textually covers the text of a list of locations.

.Description
Create a new location that refers to the smallest text area that overlaps with the text of the given locations.
The given locations should all refer to the same file but they may be overlapping or be contained in each other.
}
loc cover(list[loc] locs){
    switch(size(locs)){
    case 0: 
        throw IllegalArgument(locs, "Cover of empty list of locations");
    case 1:
        return locs[0];
    default: {
            locs = [ l | l <- locs, !any(m <- locs, m != l, isContainedIn(l, m)) ];
            locs = sort(locs, beginsBefore);
            loc first = locs[0];
            loc last = locs[-1];
 
            tops = {l.top | l <- locs};
            if(size(tops) > 1){
                throw IllegalArgument(locs, "Cover of locations with different scheme, authority or path");
            }
            if(first.begin? && last.end?){
                return first.top(first.offset, last.offset + last.length - first.offset, 
                               <first.begin.line, first.begin.column>,
                               <last.end.line, last.end.column>);
            } else if(first.offset? && last.offset?){
                return first.top(first.offset, last.offset + last.length - first.offset);
            } else {
                return first.top;
            }
        }
    }
}
