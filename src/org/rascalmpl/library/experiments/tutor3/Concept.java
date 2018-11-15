package org.rascalmpl.library.experiments.tutor3;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.StringReader;
import java.io.StringWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Concept {
	private final Path name;
	private String text = null;
	private final Path destPath;
	private boolean remote;
	private String title;
	private String synopsis;
	private String index;
	private Path libSrcPath;
	private String toc;
    private long timestamp;

	public Concept(Path name, String text, Path destPath, Path libSrcPath, long timestamp){
	    this.timestamp = timestamp;
		this.name = name;
		this.text = text;
		this.destPath = destPath;
		this.libSrcPath = libSrcPath;
		title = extract(titlePat);
		synopsis = extractSynopsis();
		index = extractIndex();
	}
	
	public void setRemote(String toc){
	    this.toc = toc;
	    remote = true;
	}
	
	public void setQuestions(){
	}
	
	public Path getName(){
		return name;
	}
	
	public String getTitle(){
		return title == null ? getName().toString() : title;
	}
	
	public String getSynopsis(){
		return synopsis;
	}
	
	public String getText(){
		return text;
	}
	
	public String getIndex(){
		return index;
	}
	
	Pattern titlePat = Pattern.compile("(?ms)^# (.*?)$");
	Pattern indexPat = Pattern.compile("(?ms)^\\.Index$\\n(.*?)$");
	Pattern synopsisPat = Pattern.compile("(?ms)^\\.Synopsis$\\n(.*?)$");
	
	private String extractSynopsis(){
		String s = extract(synopsisPat);
		return s.isEmpty() ? "" : (s.endsWith(".") ? s : (s + "."));
	}
	
	private String extractIndex(){
		String s = extract(indexPat);
		if(!s.isEmpty()){
			Matcher matcher = indexPat.matcher(text);
			text = matcher.replaceFirst("");
		}
		return s;
	}

	private String extract(Pattern pat){
		Matcher matcher = pat.matcher(text);
		
		return matcher.find() ? matcher.group(1).trim() : "";
	}
	
	private String getConceptBaseName(){
		return name.getFileName().toString();
	}
	
	public String getAnchor(){
	  int n = name.getNameCount();
	  return n >= 2 ? name.getName(n-2) + "-" + name.getName(n-1) : name.getFileName().toString();
	}
	
	private String getADocFileName(){
		return destPath.toString() + "/" + name + ("/" + getConceptBaseName()) + ".adoc";
	}
	
	private String getADocFileFolder(){
        return destPath.toString() + "/" + name;
    }
	
	public String genInclude(){
		String baseName = getConceptBaseName();
		return "include::" + baseName + "/" + baseName + ".adoc" + "[" + baseName + "]\n";
	}
	
	String getAttr(String line, String attr, String defaultVal){
		Pattern p = Pattern.compile(attr + "=([^,\\]])");
		Matcher m = p.matcher(line); 
		
		return m.find() ? m.group(1) : defaultVal;
	}
	
	String makeRenderSave(String line, String width, String height, String file){
		Pattern p = Pattern.compile("render\\((.*)\\)");
		Matcher m = p.matcher(line); 
		if(m.find()){
			String arg = m.group(1);
			if(height.isEmpty()){
				return "renderSave(" + arg + "," + file + ");";
			} else {
				return  "renderSave(" + arg + ", |file://" + file + "|, width=" + width + ", height=" + height + ");";
			}
		}
		return line;
	}
	
	String commonDefs =	
		":icons:        font\n" + 
		":iconfont-remote!:\n" +
		//":iconfont-name: font-awesome.min\n" +
		":images:       ../images/\n" +
		":table-caption!:\n" +
		":prewrap!:\n" +
		":docinfo1:\n" +
		":experimental:\n";
	
	public static String getSearchForm(){
		return
		"<form class=\"search-form\" id=\"searchbox\" action=\"/search-results.html\" method=\"get\">\n" +
		"<input class=\"search-input\" id=\"searchFor\" name=\"searchFor\" type=\"search\" placeholder=\"Search ...\">\n" +
		"<input class=\"search-submit\" id=\"submit\" type=\"submit\" value=\"&#10140;\" onkeypress=\"if(event.keyCode==13) {javascript:form.submit();}\">\n" +
		"</form>\n";
	}
	
	public static String getHomeLink(){
	  return "<a href=\"/TutorHome/index.html\"><img id=\"home\" src=\"/images/rascal-tutor-small.png\", alt=\"RascalTutor\" width=\"64\" height=\"64\"></a>";
	}
	
    private String makeRed(String result){
      StringWriter sw = new StringWriter(result.length()+5);
      for(String s :  result.split("\n")){
        sw.append("[error]#").append(s).append("#\n");
      }
      return sw.toString();
    }
    
	public void preprocess(Onthology onthology, TutorCommandExecutor repl) throws IOException {
	    assert onthology != null && repl != null;
	    File adocOut = new File(getADocFileName());
	    
	    if (adocOut.exists() && adocOut.lastModified() > timestamp) {
	        return; // we don't have to do the work if the source hasn't changed.
	    }
	    
		BufferedReader reader = new BufferedReader(new StringReader(text));

		StringWriter preprocessOut = new StringWriter();
		String line = null;
		String[] details = new String[0];
		int level = Onthology.level(name);

		while( (line = reader.readLine()) != null && !line.startsWith("#")){
			preprocessOut.append(line).append("\n");
		}
		if(line == null){
			preprocessOut.append("# ").append(name.toString()).append("\n");
		} else {
			title = line.substring(2).trim();
			if(level > 0){
				preprocessOut.append("\n[[").append(getAnchor()).append("]]\n");
				preprocessOut.append(line).append("\n");
			} else {
				line = line.replaceFirst("#",  "=");
				preprocessOut.append(line).append("\n");
				preprocessOut.append(commonDefs);
				preprocessOut.append(":LibDir: ").append(libSrcPath.toString()).append("/\n");
			}
			
			preprocessOut.append(":concept: ").append(name.toString()).append("\n");
			
			if(level == 0){
				preprocessOut.append("\n++++\n");
				preprocessOut.append(getHomeLink());
				preprocessOut.append(getSearchForm());
				preprocessOut.append("++++\n");
			}
			while( (line = reader.readLine()) != null ) {
				if(line.startsWith(".Details")){
					line = reader.readLine();
					details = line.split("\\s");
				} else if(line.startsWith("```rascal-shell") || line.startsWith("[source,rascal-shell") || line.startsWith("[source,rascal-figure")) {
					boolean isContinue = line.contains("continue");
					boolean isFigure = line.contains("figure");
					String width = "100";
					String height = "100";
					String file = "/tmp/fig.png";
					if(isFigure){
						height = getAttr(line, "height", height);
						width = getAttr(line, "width", width);
						file = getAttr(line,"file", file);
					}
					boolean mayHaveErrors = line.contains("error");
					if(line.startsWith("[")){
						line = reader.readLine();	// skip ----
						if(line == null){
							break;
						}
					}
					if(!isContinue){
						repl.reset();
					}

					startREPL(preprocessOut, mayHaveErrors);
					
					OUTER:while ((line = reader.readLine()) != null ) {
						if (line.equals("```") || line.equals("----")){
							break;
						}
						
						if (line.trim().startsWith("//")) {
						    endREPL(preprocessOut);
						    preprocessOut.append(line.trim().substring(2) + "\n");
						    while ((line = reader.readLine()) != null && line.trim().startsWith("//")) {
						        preprocessOut.append(line.trim().substring(2) + "\n");
						        if (line.equals("```") || line.equals("----")) {
						            break OUTER;
						        }
						    }
						    startREPL(preprocessOut, mayHaveErrors);
						}
						
						preprocessOut.append(repl.getPrompt()).append(line).append("\n");
					
						String resultOutput = repl.eval(line, getADocFileFolder());
						String errorOutput = repl.getErrorOutput();
						String printedOutput = repl.getPrintedOutput();
						
						if (!printedOutput.isEmpty()){
						    preprocessOut.append(printedOutput);
						} 
						
						if (!errorOutput.isEmpty()) {
						    // TODO: if !mayHaveErrors register this with the ontology, to 
						    // create a summary of all errors
						    preprocessOut.append(mayHaveErrors ? makeRed(errorOutput) : errorOutput);
						}
						
						if (!resultOutput.isEmpty()) {
						    preprocessOut.append(resultOutput);
						}
					}
					
					endREPL(preprocessOut);
				} else if(line.startsWith("```") || line.startsWith("[source")) {
				  preprocessOut.append(line).append("\n");
				  boolean inCode = false;
				  while((line = reader.readLine()) != null ) {
				    preprocessOut.append(line).append("\n");
				    if(line.equals("```") || line.equals("----")){
				      if(inCode){
				        break;
				      } else {
				        inCode = true;
				      }
				    }
				  }
				} else if(line.startsWith("loctoc::[")){
					Pattern p = Pattern.compile("loctoc::\\[(\\d*)\\]");
					Matcher m = p.matcher(line); 
					int depth = 1;
					if(m.find()){
						String intStr = m.group(1);
						depth = intStr.equals("") ? 1 : Integer.parseInt(intStr.substring(0,intStr.length()));
					}
					if(remote){
					    preprocessOut.append(toc);
					} else {
					    preprocessOut.append(onthology.genSubToc(name, depth, true, details));
					}
				} else if(line.contains("image:")){
					Pattern p = Pattern.compile("(^.*)(image::?)([^\\[]+)(\\[.*$)");
					Matcher m = p.matcher(line);
					if(m.find()){
						String pre = m.group(1);
						String image = m.group(2);
						String link = m.group(3);
						String post = m.group(4);
						if(!link.contains("{") && !link.startsWith("/")){
							link = "/{concept}/" + link;
						}
						preprocessOut.append(pre).append(image).append(link).append(post).append("\n");
					} else {
						preprocessOut.append(line).append("\n");
					}
				} else {
					preprocessOut.append(line).append("\n");
				}
			}

			preprocessOut.append(onthology.genDetails(name, details));
		}
		
		Path parent = destPath.resolve(name);
		if(!Files.exists(parent)){
			Files.createDirectory(parent);
		}
		CourseCompiler.writeFile(getADocFileName(), preprocessOut.toString());
	}

    private void endREPL(StringWriter preprocessOut) {
        preprocessOut.append("----\n");
    }

    private void startREPL(StringWriter preprocessOut, boolean mayHaveErrors) {
        preprocessOut.append("[source,rascal-shell");
        if (mayHaveErrors) {
        	preprocessOut.append("-error");
        }
        preprocessOut.append(",subs=\"verbatim,quotes,+macros\"");
        preprocessOut.append("]\n").append("----\n");
    }

}
