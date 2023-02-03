public class PLM_SalesTeamReportDatatableWrapper {
	
	private List<Product__c> productList;
	
	private String packageVerionName;
	
	private String packageLineName;
	
	
	public List<Product__c> getProductList(){
		return productList;
	}
	
	public void setProductList(List<Product__c> productList){
		this.productList = productList;
	} 

	public String getPackageVerionName(){
		return packageVerionName;
	}
	
	public void setPackageVerionName(String packageVerionName){
		this.packageVerionName = packageVerionName;
	} 


	public String getPackageLineName(){
		return packageLineName;
	}
	
	public void setPackageLineName(String packageLineName){
		this.packageLineName = packageLineName;
	} 

	

}