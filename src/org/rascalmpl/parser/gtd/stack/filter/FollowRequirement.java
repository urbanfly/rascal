/*******************************************************************************
 * Copyright (c) 2009-2011 CWI
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:

 *   * Arnold Lankamp - Arnold.Lankamp@cwi.nl
*******************************************************************************/
package org.rascalmpl.parser.gtd.stack.filter;

public class FollowRequirement implements ICompletionFilter{
	private final char[] required;
	
	public FollowRequirement(char[] required){
		super();
		
		this.required = required;
	}
	
	public boolean isFiltered(char[] input, int start, int end){
		if((end + required.length) <= input.length){
			for(int i = required.length - 1; i >= 0; --i){
				if(input[end + i] != required[i]) return true;
			}
			return false;
		}
		
		return true;
	}
}
