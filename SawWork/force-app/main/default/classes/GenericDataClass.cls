public virtual class GenericDataClass {
	
	private String pageName;
	
	private static Map<String,GenericDataClass> classNameToDataClassMap;
	
	static
	{
		initClassNameToDataClassMap();
	}
	public GenericDataClass()
	{
		
	}
    
    public String getPageName()
    {
    	return this.pageName;
    }
    public String getPageName(String url)
    {
    	System.debug('page url : '+url);
    	pageName='';
    	if(url.indexOf('/apex/') != -1)
    	{
	    	if(url.indexOf('?') != -1 )
	    	{
	    	  pageName=url.subString(url.indexOf('/apex/')+6,url.indexOf('?'));
	    	}
	    	else 
	    	{
	    	  pageName=url.subString(url.indexOf('/apex/')+6);
	    	}
    	}
    	return pageName;
    }
    
    public static GenericDataClass getDataClassObject(String className)
    {
    	return classNameToDataClassMap.get(className);
    }
    
    public static void initClassNameToDataClassMap()
    {
    	if(classNameToDataClassMap ==null)
    	{
    		classNameToDataClassMap=new Map<String,GenericDataClass>();
    	}
    	classNameToDataClassMap.put('PLM_LaunchItemApprovalGeneric',new PLM_LaunchItemApprovalDataClass());
    	
    }
}