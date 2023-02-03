/* ***** BEGIN LICENSE BLOCK *****
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * ***** END LICENSE BLOCK ***** */

/**
 * This Public Suffix Service (PSS) class reads a file of rules describing
 * TLD-like domain names and makes rulings on passed hostnames/domain-names
 * based of the data file content. For a complete description of the expected
 * file format and parsing rules, see <a
 * href="http://wiki.mozilla.org/Gecko:Effective_TLD_Service">Effective TLD Service</a>
 * and <a href="http://www.publicsuffix.org">Public Suffix</a>.
 * 
 * <p>This class is a rough port of the c++ file, <a
 * href="http://www.koders.com/cpp/fid3F3968962A800C642821733B91E16316B53753BF.aspx">nsEffectiveTLDService.cpp</a>
 * originally developed by Pamela Greene &lt;pamg.bugs ATGMAILDOTCOM&gt;. The
 * class uses the first <code>effective_tld_names.dat</code> found on
 * the CLASSPATH.  The bundled jar has a version of the file taken from
 * <a href="publicsuffix.org">Public Suffix</a> on 10/22/2007.
 * 
 * <p>To use this class, instantiate an instance and then call
 * {@link #getEffectiveTLDLength(String)} passing the hostname to interrogate..
 * 
 * <p>The following description of how the code works is copied from the head
 * of the c++ file.
 * 
 * <p>
 * The list of subdomain rules is stored as a wide tree of SubdomainNodes,
 * primarily to facilitate multiple levels of wildcards.  Each node represents
 * one level of a particular rule in the list, and stores meta-information about
 * the rule it represents as well as a list (hash) of all the subdomains beneath
 * it.
 * <p>
 * <ul><li>stopOK: If true, this node marks the end of a rule.</li>
 * <li>exception: If true, this node marks the end of an exception rule.</li>
 * </ul>
 *<p>
 *For example, if the effective-TLD list contains
 * <pre>foo.com
 * *.bar.com
 * !baz.bar.com
 * </pre>
 * then the subdomain tree will look like this (conceptually; the actual order
 * of the nodes in the hashes is not guaranteed):
 * <pre>
 * +--------------+
 * | com          |
 * | exception: 0 |        +--------------+
 * | stopOK: 0    |        | foo          |
 * | children ----|------> | exception: 0 |
 * +--------------+        | stopOK: 1    |
 *                         | children     |
 *                         +--------------+
 *                         | bar          |
 *                         | exception: 0 |        +--------------+
 *                         | stopOK: 0    |        | *            |
 *                         | children ----|------> | exception: 0 |
 *                         +--------------+        | stopOK: 1    |
 *                                                 | children     |
 *                                                 +--------------+
 *                                                 | baz          |
 *                                                 | exception: 1 |
 *                                                 | stopOK: 1    |
 *                                                 | children     |
 *                                                 +--------------+
 *</pre>
 *</p>
 *<p>TODO: Add support for IDN (See java6 java.net.IDN).</p>
 *<p>TODO: Add support for multiple data files</p>
 *@author stack
 */
public with sharing class TLDParser {
  public final SubdomainNode root = new SubdomainNode(false, false);
  private static final String WILDCARD = '*';
  private static final String Exception_rule = '!';
  private static final Pattern WHITESPACE = Pattern.compile('\\s+');
  public static final String DOT = '.';
  
  public static final String DATA_FILENAME = 'effective_tld_names.dat';
  
  
  /**
   * Loads data file and creates a tree of subdomain nodes in memory used
   * finding the effective TLD.
   * @throws IOException 
   * @throws UnsupportedEncodingException 
   */
  /*public PSS() throws UnsupportedEncodingException, IOException {
    load();
  }*/

  /**
   * Finds the length in bytes of the effective TLD for the given
   * <code>hostname</code>
   * @param hostname Hostname to check.
   * @return length of effective-TLD portion in passed <code>hostname</code>.
   * If passed string is all effective-TLD -- e.g. if you '.com' -- then we
   * return -1.  If no effective-TLD found, then returns
   * <code>hostname.length()</code>.
   */
  public Integer getEffectiveTLDLength(String hostname) {
    final String normalizedHostname = normalizeHostname(hostname);
    Integer lastDot = normalizedHostname.length();
    
    loadTLD(hostname);
    
    for (SubdomainNode node = this.root; lastDot > 0;) {
      Integer nextDotLoc = normalizedHostname.substring(0,lastDot - 1).lastIndexOf('.');
      node = findNode(node,
        normalizedHostname.substring(nextDotLoc + 1, lastDot), false);
        //.debug(LoggingLevel.INFO,'Next Dot:'+ nextDotLoc);
        //System.debug(LoggingLevel.INFO, 'Next Node: '+node);
      if (node == null) {
        break;
      }
      lastDot = nextDotLoc;
      if (node.isException()) {
        // Exception rules use one fewer levels than were matched.
        break;
      }
      if (node.isStopOK()) {
        break;
      }
    }
    return lastDot;
  }

  /**
   * Normalizes characters of <code>hostname</code>. ASCII names are
   * lower-cased.  TOOD: If names using other characters than ASCII
   * need to be normalized with a IIDNService::Normalize, RFC 3454.
   * @param hostname
   * @return normalized hostname.
   */
  String normalizeHostname(final String hostname) {
    boolean isLowercase = false;
   /* boolean isAscii = true;
    for (Integer i = 0; i < hostname.length(); i++) {
      String c = hostname.substring(i, i+1);
      if (c >= 128) {
        isAscii = false;
        break;
      }
      if (!Character.isLowerCase(c)) {
        isLowercase = false;
      }
    }
    if (!isAscii) {
      // TODO: If java 6, then there is java.net.IDN#toAscii(hostname).
      throw new Exception('No support yet for IDN: TODO');
    }*/
    return isLowercase? hostname: hostname.toLowerCase();
  }


	public void loadTLD(String domain){
		
		StaticResource defaultResource = [Select  s.Body From StaticResource s where s.Name LIKE 'moz_tld_list%'];
        blob tempB = defaultResource.Body;
       	String contentFile = tempB.toString();
		//System.debug(contentFile);
		
		String[] filelines = contentFile.split('\n');
    	//List<object_to_Create__c> defaults = new List<object_to_Create__c>();
    	
    	
    	String hostname = WHITESPACE.split(domain, 2)[0];
   	  	//for (Integer dotLoc = hostname.length(); dotLoc >= 0;) {
      		Integer dotLoc = hostname.length();	
      		Integer nextDocLoc = hostname.substring(0,dotLoc - 1).lastIndexOf(DOT);
      		String subdomain = hostname.substring(nextDocLoc + 1, dotLoc);
      		dotLoc = nextDocLoc;
      		//node = findNode(node, subdomain, true);
    	//}
    	
    	String sdstar = '*.' + subdomain;
    	//System.debug('Subdomain: ' + subdomain + 'star: ' + sdstar);
    	
       	for (Integer i=1;i<filelines.size();i++)
        {
        	
        	String line = filelines[i];
        	//System.debug('Line: ' + line);
        	if (line.length() <= 0 || line.startsWith('//')) {
        		continue;
      		}
      		
      		
      		if(line == subdomain || line == (sdstar)) {
      			//found it, now to find the next domain.
      			addEffectiveTLDEntry(this.root, line);
      			i++;
      			//if(!filelines[i].contains(DOT)){
      			//	break;
      			//}
      			while (i <filelines.size() && filelines[i].contains(DOT))
      			{	
      			line = filelines[i];
      			//System.debug(LoggingLevel.INFO,'Matched Line: ' + line);
      			addEffectiveTLDEntry(this.root, line);
      			i++;
      			
      			}
      			break;
      			
      		}
      		
      		
      		//System.debug(LoggingLevel.INFO,line);
      		//addEffectiveTLDEntry(this.root, line);
        }
		
		
	}


  /**
   * Load effective TLD file from the CLASSPATH.
   * @throws IOException 
   * @throws UnsupportedEncodingException 
   */
  public void load() {
  	
  	StaticResource defaultResource = [Select  s.Body From StaticResource s where s.Name LIKE 'moz_tld_list%'];
        blob tempB = defaultResource.Body;
       	String contentFile = tempB.toString();
		//System.debug(contentFile);
		
		String[] filelines = contentFile.split('\n');
    	//List<object_to_Create__c> defaults = new List<object_to_Create__c>();
       	for (Integer i=1;i<filelines.size();i++)
        {
        	
        	String line = filelines[i];
        	if (line.length() <= 0 || line.startsWith('//')) {
        		continue;
      		}
      		//System.debug(LoggingLevel.INFO,line);
      		addEffectiveTLDEntry(this.root, line);
        }
  /*
    URL u = this.getClass().getResource("/" + DATA_FILENAME);
    if (u == null) {
      throw new FileNotFoundException(DATA_FILENAME + " not on CLASSPATH");
    }
    BufferedReader br =
      new BufferedReader(new InputStreamReader(u.openStream(), "UTF-8"));
    for (String line = null; (line = br.readLine()) != null;) {
      if (line.length() <= 0 || line.startsWith("//")) {
        continue;
      }
      addEffectiveTLDEntry(this.root, line);
    }*/
  }
 
  /**
   * Given a parent node and a candidate <code>subdomain</code>, searches the
   * parent's children for a matching subdomain and returns a pointer to the
   * matching node if one was found.  If no exact match was found and
   * <code>create</code> is true, creates a new child node for the given
   * <code>subdomain</code> and returns that.
   * If no exact match was found an <code>create</code> is false, looks for
   * a wildcard node (*) instead.  If no wildcard node is found either,
   * returns null.
   * @param node
   * @param subdomain
   * @param create Typically true when the subdomain tree is being
   * built, and false when it is being searched to determine a hostname's
   * effective TLD.
   * @return
   */
  private SubdomainNode findNode(final SubdomainNode node,
      final String subdomain, final boolean create) {
    boolean exception_b = subdomain != null && subdomain.startsWith(Exception_rule);
    String key = exception_b? subdomain.substring(1): subdomain;
    SubdomainNode newNode = node.getChildren().get(key);
    //System.debug(LoggingLevel.INFO,subdomain);
    //System.debug(LoggingLevel.INFO,newNode);
    if (newNode != null) {
      return newNode;
    }
    if (create) {
      // Create it and add to parent.
      SubdomainNode subNode = new SubdomainNode(exception_b, false);
      node.getChildren().put(key, subNode);
      return subNode;
    }
    return node.getChildren().get(WILDCARD);
  }

  /**
   * Adds the given domain name rule to the effective-TLD tree.
   * @param m Map to add too.
   * @param line Line that starts with a hostname.
   */
  void addEffectiveTLDEntry(SubdomainNode node,
      final String line) {
    String hostname = WHITESPACE.split(line, 2)[0];
    for (Integer dotLoc = hostname.length(); dotLoc >= 0;) {
      Integer nextDocLoc = hostname.substring(0,dotLoc - 1).lastIndexOf(DOT);
      String subdomain = hostname.substring(nextDocLoc + 1, dotLoc);
      dotLoc = nextDocLoc;
      node.stopOK = false;
      node = findNode(node, subdomain, true);
    }
    
    // The last node in an entry is by definition a stop-OK node.
    node.setStopOK();
  }
  
  public void dump() {
    dump(this.root.getChildren(), 0);
  }
  
  private void dump(final Map<String, SubdomainNode> node, final Integer offset) {
    if (node == null || node.size() == 0) {
      return;
    }
    //for (Map.Entry<String, SubdomainNode> e: node.entrySet()) {
     for(String key: node.keySet()){
      for (Integer i = 0; i < offset; i++) {
        System.debug(LoggingLevel.INFO,' ');
      }
      System.debug(LoggingLevel.INFO,key + ': ' + node.get(key));
      dump(node.get(key).getChildren(), offset + 1);
    }
  }

  /**
   * Immmutable subdomain node.
   */
  public class SubdomainNode {
    final boolean exception_b;
    boolean stopOK;
    final Map<String, SubdomainNode> children;

    /**
     * Create node with no children.
     * @param ex
     * @param stop
     */
    public SubdomainNode(final boolean ex, final boolean stop) {
      this(ex, stop, new Map<String, SubdomainNode>());
    }

    public SubdomainNode(final boolean ex, final boolean stop,
        final Map<String, SubdomainNode> c) {
      this.exception_b = ex;
      this.children = c;
      this.stopOK = stop;
    }

    public boolean isException() {
      return this.exception_b;
    }

    public boolean isStopOK() {
      return this.stopOK;
    }
    
    public void setStopOK() {
      this.stopOK = true;
    }

    public Map<String, SubdomainNode> getChildren() {
      return this.children;
    }
    
   /*
    public String toString() {
      return 'exception: ' + this.exception_b + ', stopOK: ' + this.stopOK +
        ', children: ' + (this.children == null? 0: this.children.size());
    }*/
  }
  
  /**
   * Dumps the in-memory map of subdomains on STDOUT.
   * @param args
   * @throws UnsupportedEncodingException
   * @throws IOException
   */
 /* public static void main(String[] args)
  throws UnsupportedEncodingException, IOException {
    PSS pss = new PSS();
    pss.dump();
  }
*/

}