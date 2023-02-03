/**
    This is the controller and backing bean class for PLM_SalesTeamReportPage 

*/

public class PLM_SalesTeamReportController {
    

    List<PLM_SalesTeamReportDatatableWrapper> pdwList  = new List<PLM_SalesTeamReportDatatableWrapper>();

    String[] selectedSolutionCategory = new List<String>();
    String[] selectedPkgLine = new List<String>();
    String[] selectedProductLine = new List<String>();
    
    List<Product__c> productList = new List<Product__c>();      
    List<Package__c> packageList = new List<Package__c>();

    List<Product_Line__c> displayProductLineList = new List<Product_Line__c>();
    List<Solution_PackageVersion__c> spkgVerList = new List<Solution_PackageVersion__c>();

    Set<Id> packageIdList = new Set<Id>(); 
    
    
    
        /**
        This gets package versions based on selected package lines  
    */
    public List<SelectOption> getProductLineList(){
        
        List<SelectOption> productLineList = new List<SelectOption>();
        SelectOption sop;
        
        
        displayProductLineList = [Select  p.Id, p.Name From Product_Line__c p ];
        
        for(Product_Line__c plc: displayProductLineList ){
            sop = new SelectOption(plc.Id,plc.Name);
            productLineList.add(sop);
        }       
        
        return productLineList;
        
    }
    
    
    /**
        This lists donwe the available Solution Category
    */  
    public List<SelectOption> getSolutionCategoryPickList(){

        List<SelectOption> solutionPickList = new List<SelectOption>();
        Set<Id> solnCatIdSet = new Set<Id>();
        SelectOption sop;
        
        for(ProductLine_SolutionCategory__c soln: [Select Solution_Category__c,  Solution_Category__r.Name From ProductLine_SolutionCategory__c where Product_Line__c = :selectedProductLine order by Solution_Category__r.Name]){
            
            if(solnCatIdSet.add(soln.Solution_Category__c) && soln.Solution_Category__c!=null){
                sop = new SelectOption(soln.Solution_Category__c, soln.Solution_Category__r.Name);
                solutionPickList.add(sop);
            }
        }
        
        return solutionPickList;
        
    }

    
        /**
            This method gets the list of package lines based on the solution version selected   
        */
        public List<SelectOption> getPackageLinePickList(){
            
            List<SelectOption> solutionPickList = new List<SelectOption>();
            List<Id> productIdList = new List<Id>();
            Set<Id> packageLineIdSet = new Set<Id>();
            SelectOption sop;
			packageIdList = new Set<Id>();

            spkgVerList = [SELECT Package_Version__c, Package_Version__r.Name,Package_Version__r.Package__c  FROM Solution_PackageVersion__c where Solution__c in
            (SELECT Id FROM Solution__c where Solution_Category__c  in :selectedSolutionCategory and Solution_Expiration_Date__c = null) 
            ];

            for(Solution_PackageVersion__c soln: spkgVerList ){
                packageIdList.add(soln.Package_Version__r.Package__c);
            }
            
            packageList = [SELECT Id, PackageLines__c, PackageLines__r.Name FROM Package__c where Id in :packageIdList order by PackageLines__r.Name];
            
            for(Package__c pkg: packageList ){
                if(packageLineIdSet.add(pkg.PackageLines__c) && pkg.PackageLines__c!=null){
                    sop = new SelectOption(pkg.PackageLines__c, pkg.PackageLines__r.Name);
                    solutionPickList.add(sop);              
                }
            }       
            
            return solutionPickList;
            
        }
        
        
    
    /**
        Lists the solutions available for a selected solution category. 
    public List<SelectOption> getSolutionPickList(){

        List<SelectOption> solutionPickList = new List<SelectOption>();
        SelectOption sop;
        
        for(Solution__c soln: [SELECT Id, Solution_Category__r.Name, Solution_Version__c FROM Solution__c where Solution_Category__c in :selectedSolutionCategory]){
            sop = new SelectOption(soln.Id, soln.Solution_Category__r.Name + ':' + soln.Solution_Version__c );
            solutionPickList.add(sop);
        }
        
        return solutionPickList;
        
    }
    
    private List<Id> getPackageVersionProduct(){
        
        
        Set<Id> packageVersionId = new Set<Id>(); 
        
        for(PackageVersion_Products__c pkgverprd: [SELECT Product__c, Package_Version__c,Package_Version__r.Package_Version__c  FROM PackageVersion_Products__c where Package_Version__c = :selectedPkgVersion]){
            
            packageVersionId.add(pkgverprd.Package_Version__c);
            
            if(pkgverprodMap.containsKey(pkgverprd.Package_Version__c)){
                pkgverprodMap.get(pkgverprd.Package_Version__c).add(pkgverprd.Product__c);
            }
            else{
                List<Id> temp = new List<Id>();
                temp.add(pkgverprd.Product__c);
                pkgverprodMap.put(pkgverprd.Package_Version__c, temp);
            }
        }
        
        return new List<Id>(packageVersionId);
        
    }
    */  

    
    /**
    ****************************************************************************************************************************************************************
    ****************************************************************************************************************************************************************
            The method which is invoked when user wants to generate a report    
    ****************************************************************************************************************************************************************
    ****************************************************************************************************************************************************************
    **/
    public PageReference generateReport(){
            
            PLM_SalesTeamReportDatatableWrapper pdw;
            pdwList.clear();
            
            List<Package_Version__c> displayPackageList = new List<Package_Version__c>();
            Map<Id, String> pkgVerIdVariantTextMap = new Map<Id, String> ();
            Map<Id, Id> pkgVerPkgLineIdMap = new Map<Id, Id> ();
            Map<Id, String>  packageLineNameMap = new Map<Id, String>();
            Map<Id, String> veridPackageLineNameMap = new Map<Id, String>();
            String[] selectedPkgVersion = new List<String>();
            

            // Get approved package versions for the selected package line and also it's package variant and package line
            displayPackageList = [SELECT Id, Package__r.Variant__c, Package__r.PackageLines__c,Package_Version__c from Package_Version__c where Package__c  in ( SELECT Id FROM Package__c where PackageLines__c in :selectedPkgLine) 
            and  Approval_Status_Code__c = '410'];
			        
            for(Package_Version__c pkg: displayPackageList ){
                selectedPkgVersion.add(pkg.Id);
                pkgVerIdVariantTextMap.put(pkg.Id, pkg.Package__r.Variant__c);
                pkgVerPkgLineIdMap.put(pkg.Id, pkg.Package__r.PackageLines__c);
            }       
            
            // For the selected package version get the list of package versions and products.  
            List<PackageVersion_Products__c> packageVersionProdList = [SELECT Product__c,Package_Version__c  FROM PackageVersion_Products__c where
             Package_Version__c = :selectedPkgVersion];

            // A map of product and package version id. Product Id is the key
            Map<Id,Id> packageKeyProdIdMap = new Map<Id,Id>();
    
            for(PackageVersion_Products__c pvpc: packageVersionProdList){
                 packageKeyProdIdMap.put(pvpc.Product__c, pvpc.Package_Version__c);
                 
            }
            
            
            // A map of package version id and products. Key is package version and value is a list of Product__c which belong to the package ver id as the key
            Map<Id, List<Product__c>> packageKeyProdValueMap = new Map<Id, List<Product__c>>();
            
            // The product that will be displayed
            List<Id> selectedProductId = new List<Id>(packageKeyProdIdMap.keySet());
            
            // Details of all products for the selected package versions 
            productList = [Select Id, Name,Product_Category__r.Name, Product_Category__r.Product_Type__c, Product_Category__r.Product_Line__c,Product_Phase__c 
            From Product__c  where Id in :selectedProductId  
            order by Product_Category__r.Product_Line__c, Product_Category__r.Product_Type__c, Product_Phase__c];

			
            for(Product__c prd: productList){
                
            Id packageVerId = packageKeyProdIdMap.get(prd.Id);
            
                if(packageVerId != null){
    
                        if( packageKeyProdValueMap.containsKey(packageVerId)){
                            packageKeyProdValueMap.get(packageVerId).add(prd);
                        }
                        else{
                            List<Product__c> temp = new List<Product__c>();
                            temp.add(prd);
                            packageKeyProdValueMap.put(packageVerId, temp);
                        }
                }
            
            }


            
                        
            List<Id> pkgLineIdList = pkgVerPkgLineIdMap.values();
            List<PackageLine__c> pkgLineList =  [Select p.Id, p.PackageLine_Name__c From PackageLine__c p where Id in :pkgLineIdList];
            
            
            for(PackageLine__c plc: pkgLineList){
                packageLineNameMap.put(plc.Id, plc.PackageLine_Name__c);
            }
            
            List<Id> pkgverIdList = new List<Id>();
            pkgverIdList.addAll(pkgVerPkgLineIdMap.keySet());
            
            for(Id pkgVerId: pkgverIdList){
                veridPackageLineNameMap.put(pkgVerId, packageLineNameMap.get(pkgVerPkgLineIdMap.get(pkgVerId)));
            }


            // Populate the backing bean for datatable on view
            for(Id pkgId : packageKeyProdValueMap.keySet()){
                
                PLM_SalesTeamReportDatatableWrapper strdw = new PLM_SalesTeamReportDatatableWrapper();
                strdw.setPackageVerionName(pkgVerIdVariantTextMap.get(pkgId));
                strdw.setPackageLineName(veridPackageLineNameMap.get(pkgId));
                strdw.setProductList(packageKeyProdValueMap.get(pkgId));
                pdwList.add(strdw);
            }
            
            
            return null;
    }


    
    
    
    /**
        getters and setters for class level variables
    */
    
    public String[] getSelectedSolutionCategory(){
        return selectedSolutionCategory;
    }
    
    public void setSelectedSolutionCategory(String[] selectedSolutionCategory){
        this.selectedSolutionCategory = selectedSolutionCategory;
        
    }

    
    public String[] getSelectedPkgLine(){
        return selectedPkgLine;
    }
    
    public void setSelectedPkgLine(String[] selectedPkgLine){
        this.selectedPkgLine = selectedPkgLine;
        
    }

    /*public List<Product__c> getProductList(){
        return productList;
    }
    
    
    public void setProductList(List<Product__c> productList){
        this.productList = productList;
        
    }

    public String[] getSelectedPkgVersion(){
        return selectedPkgVersion;
    }
    
    public void setSelectedPkgVersion(String[] selectedPkgVersion){
        this.selectedPkgVersion = selectedPkgVersion;
    }       
	*/

    public List<PLM_SalesTeamReportDatatableWrapper> getPdwList(){
        return pdwList;
    }
    
    public void setPdwList(List<PLM_SalesTeamReportDatatableWrapper> pdwList){
        this.pdwList = pdwList;
        
    }

    public String[] getSelectedProductLine(){
        return selectedProductLine;
    }
    
    public void setSelectedProductLine(String[] selectedProductLine){
        this.selectedProductLine = selectedProductLine;
    }


}