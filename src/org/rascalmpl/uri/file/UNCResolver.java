package org.rascalmpl.uri.file;

import java.io.FileNotFoundException;
import java.io.IOException;

import io.usethesource.vallang.ISourceLocation;

/**
 * Implements the UNC-available network shares on Windows systems.
 */
public class UNCResolver extends FileURIResolver {
    private boolean onWindows = System.getProperty("os.name").toLowerCase().startsWith("win");

    public UNCResolver() throws IOException {
        super();
    }

    @Override
    protected String getPath(ISourceLocation uri) {
        if (!onWindows) {
            throw new RuntimeException(new FileNotFoundException(uri.toString() + "; UNC is only available on Windows"));
        }
        
        if (uri.hasAuthority()) {
            // downstream methods will use `new File` and `new FileInputStream`
            // which are able to parse UNC's on Windows.
			return "\\\\" + uri.getAuthority() + "\\" + uri.getPath();
		}
		else {
			// just a normal absolute path
			return uri.getPath();
		}
    }
    
    @Override
    public String scheme() {
        return "unc";
    }
}