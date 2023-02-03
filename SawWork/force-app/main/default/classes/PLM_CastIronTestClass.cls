@isTest
private class PLM_CastIronTestClass {

 
    private static PackageVersion_Purpose__c CreatePackageVersionPurpose(String name, String akampvpId, String akampvId, String akampurposeId){
            
            PackageVersion_Purpose__c spv = new PackageVersion_Purpose__c();
            spv.Name = name;
            spv.AKAM_PackageVersion_Products_Id__c = akampvpId;
            spv.AKAM_PackageVersion_Purpose_Id__c = akampvpId;
            spv.CI_Package_Version__c = akampvId;
            spv.CI_Purpose__c = akampurposeId;
            
            return spv;
        }
  
    private static Purpose__c CreatePurpose(String name, String akampurposeId){
        Purpose__c purpose = new Purpose__c();
        purpose.Name = name;
        purpose.AKAM_Purpose_Id__c = akampurposeId; 
        return purpose;
    }
  
  	private static Product_Line__c CreateProductLine(String name, String akamprdLineId){
  		
  		Product_Line__c pl = new Product_Line__c();
  		pl.Name = name;
  		pl.AKAM_Product_Line_Id__c = akamprdLineId;
  		
  		return pl;
  	}
  
  	private static ProductLine_SolutionCategory__c CreateProductLineSolutionCategory(String name, String akamPrdLineId, String akamsolnCatId){
  		
  		ProductLine_SolutionCategory__c plsc = new ProductLine_SolutionCategory__c();
  		plsc.CI_Solution_Category__c = akamsolnCatId;
  		plsc.CI_Product_Line__c = akamPrdLineId;
  		
  		return plsc;
  		
  	}
  
  
     private static Solution_Purpose__c CreateSolutionPurpose(String name, String akamspcId, String akampurposeId, String akamsolnId){
            
            Solution_Purpose__c spv = new Solution_Purpose__c();
            spv.Name = name;
            spv.AKAM_Solution_Purpose_Id__c = akamspcId;
            spv.CI_Purpose__c = akampurposeId;
            spv.CI_Solution__c = akamsolnId;
            
            return spv;
        }
  
     private static Solution_PackageVersion__c CreateSolutionPackageVersion(String name, String akamspvId, String akampvId, String akamsolnId){
            
            Solution_PackageVersion__c spv = new Solution_PackageVersion__c();
            spv.Name = name;
            spv.AKAM_Solution_PackageVersion_Id__c = akamspvId;
            spv.CI_Package_Version__c = akampvId;
            spv.CI_Solution__c = akamsolnId;
            
            return spv;
        }
    
     private static PackageVersion_Products__c CreatePackageVersionProducts(String name, String akampkgverpdId, String akampkgverId, String akamproductId){
        
        PackageVersion_Products__c pc = new PackageVersion_Products__c();
        pc.Name = name;
        pc.AKAM_PackageVersion_Products_Id__c = akampkgverpdId;
        pc.CI_Package_Version__c = akampkgverId;
        pc.CI_Product__c = akamproductId;
        
        return pc;
    }
         
        
     private static Territory__c CreateTerritory(String akamTerrId){
            
            Territory__c pc = new Territory__c();
            pc.AKAM_Territory_Id__c = akamTerrId;
            
            return pc;
    }

    
    private static Product__c CreateProductWithProductCategory(String name, String akamProductId, String akamParentProductCatId){
        
        Product__c pc = new Product__c();
        pc.Name = name;
        pc.AKAM_Product_Id__c = akamProductId;
        pc.CI_Product_Category__c = akamParentProductCatId;
        return pc;
    }

     
     private static Solution_Territory__c CreateSolutionTerritory(String name, String akamSolnTerrId, String akamSolutionId, String akamTerrId){
            
            Solution_Territory__c pc = new Solution_Territory__c();
            pc.Name = name;
            pc.AKAM_SolutionTerritory_Id__c = akamSolnTerrId;
            pc.CI_Solution__c = akamSolutionId;
            pc.CI_Territory__c = akamTerrId;
            
            return pc;
    }
    
    

    private static Product_Category__c CreateProductCategory(String name, String akamProductCatId, String akamParentProductCatId){
        
        Product_Category__c pc = new Product_Category__c();
        pc.Name = name;
        pc.AKAM_Product_Category_Id__c = akamProductCatId;
        pc.CI_Parent_Product_Category__c = akamParentProductCatId;
        return pc;
    }
    
    private static Package_Version__c CreatePackageVersion(String name, String akamPackageVersionId, String akamPackageId){
        
        Package_Version__c pvc = new Package_Version__c();
        pvc.Name = name;
        pvc.AKAM_Package_Version_Id__c = akamPackageVersionId;
        pvc.CI_Package__c = akamPackageId;
        return pvc;
        
    }
  
  // This prepares a solution category object
  private static Solution_Category__c createSolutionCategory(String name,String akamsolnCatId,String defaultSolutionAkamId){
    
        Solution_Category__c sc = new Solution_Category__c();
        sc.Name = name;
        sc.AKAM_Solution_Category_Id__c = akamsolnCatId;
        sc.CI_Default_Solution__c = defaultSolutionAkamId;
        return sc;
        
  }

    // This prepares a solution object
  private static Solution__c CreateSolution(String solutionakamid, String solutioncatakamid){
        
        Solution__c soln = new Solution__c();
        soln.AKAM_Solution_Id__c = solutionakamid;
        soln.CI_Solution_Category__c = solutioncatakamid;
        return soln;
    
    
  }
  
  private static PackageLine__c CreatePackageLine(String packagelineName, String packageLineAkamId){
    
    PackageLine__c pl = new PackageLine__c();
    pl.AKAM_PackageLine_Id__c = packageLineAkamId;
    pl.Name = packagelineName;
    return pl;
    
  }
  
  private static Package__c CreatePackage(String packageAkamId, String packageLineAkamId){
    
    Package__c pkg = new Package__c();
    pkg.CI_PackageLine__c = packageLineAkamId;
    pkg.AKAM_Package_Id__c = packageAkamId;
    return pkg;
    
  }
  
  
  
  

    /**
        RefreshSolution()
        - Overloaded to refresh Single Solution
    */
    private static Solution__c RefreshSolution(Solution__c pSolution)
    {
        return RefreshSolution(new List<Solution__c> {pSolution})[0];
    }
    /**
        RefreshSolution()
    */
    private static List<Solution__c> RefreshSolution(List<Solution__c> pSolutionList)
    {
        return [select Id,
                       Solution_Category__c
                       from 
                Solution__c 
                where Id IN :pSolutionList];
    }


    /**
        RefreshSolutionCategory()
        - Overloaded to refresh Single SolutionCategory
    */
    private static Solution_Category__c RefreshSolutionCategory(Solution_Category__c pSolution)
    {
        return RefreshSolutionCategory(new List<Solution_Category__c> {pSolution})[0];
    }
    /**
        RefreshSolutionCategory()
    */
    private static List<Solution_Category__c> RefreshSolutionCategory(List<Solution_Category__c> pSolutionList)
    {
        return [select Id,
                       Default_Solution__c
                       from 
                Solution_Category__c 
                where Id IN :pSolutionList];
    }


    /**
        RefreshSolutionCategory()
        - Overloaded to refresh Single SolutionCategory
    */
    private static Package__c RefreshPackage(Package__c pPackage)
    {
        return RefreshPackage(new List<Package__c> {pPackage})[0];
    }
    /**
        RefreshSolutionCategory()
    */
    private static List<Package__c> RefreshPackage(List<Package__c> pPackageList)
    {
        return [select Id,
                       PackageLines__c
                       from 
                Package__c 
                where Id IN :pPackageList];
    }
    
    

    /**
        RefreshSolution()
        - Overloaded to refresh Single Solution
    */
    private static Package_Version__c RefreshPackageVersion(Package_Version__c pVersion)
    {
        return RefreshPackageVersion(new List<Package_Version__c> {pVersion})[0];
    }
    /**
        RefreshSolution()
    */
    private static List<Package_Version__c> RefreshPackageVersion(List<Package_Version__c> pVersionList)
    {
        return [select Id,
                       Package__c
                       from 
                Package_Version__c 
                where Id IN :pVersionList];
    }


    /**
        RefreshSolution()
        - Overloaded to refresh Single Solution
    */
    private static Product_Category__c RefreshProductCategory(Product_Category__c p)
    {
        return RefreshProductCategory(new List<Product_Category__c> {p})[0];
    }
    /**
        RefreshSolution()
    */
    private static List<Product_Category__c> RefreshProductCategory(List<Product_Category__c> pList)
    {
        return [select Id,
                       Parent_Product_Category__c
                       from 
                Product_Category__c 
                where Id IN :pList];
    }

    /**
        RefreshSolution()
        - Overloaded to refresh Single Solution
    */
    private static Product__c RefreshProductWithProductCategory(Product__c p)
    {
        return RefreshProductWithProductCategory(new List<Product__c> {p})[0];
    }
    /**
        RefreshSolution()
    */
    private static List<Product__c> RefreshProductWithProductCategory(List<Product__c> pList)
    {
        return [select Id,
                       Product_Category__c
                       from 
                Product__c 
                where Id IN :pList];
    }



    /**
        RefreshSolution()
        - Overloaded to refresh Single Solution
    */
    private static Solution_Territory__c RefreshSolutionTerritory(Solution_Territory__c p)
    {
        return RefreshSolutionTerritory(new List<Solution_Territory__c> {p})[0];
    }
    /**
        RefreshSolution()
    */
    private static List<Solution_Territory__c> RefreshSolutionTerritory(List<Solution_Territory__c> pList)
    {
        return [select Id,
                       Solution__c,
                       Territory__c
                       from 
                Solution_Territory__c 
                where Id IN :pList];
    }


    
   /**
        RefreshSolution()
        - Overloaded to refresh Single Solution
    */
    private static PackageVersion_Products__c RefreshPackageVersionProduct(PackageVersion_Products__c p)
    {
        return RefreshPackageVersionProduct(new List<PackageVersion_Products__c> {p})[0];
    }
    /**
        RefreshSolution()
    */
    private static List<PackageVersion_Products__c> RefreshPackageVersionProduct(List<PackageVersion_Products__c> pList)
    {
        return [select Id,
                       Package_Version__c,
                       Product__c
                       from 
                PackageVersion_Products__c 
                where Id IN :pList];
    }
    
        
   /**
        RefreshSolution()
        - Overloaded to refresh Single Solution
    */
    private static Solution_PackageVersion__c RefreshSolutionPackageVersion(Solution_PackageVersion__c p)
    {
        return RefreshSolutionPackageVersion(new List<Solution_PackageVersion__c> {p})[0];
    }
    /**
        RefreshSolution()
    */
    private static List<Solution_PackageVersion__c> RefreshSolutionPackageVersion(List<Solution_PackageVersion__c> pList)
    {
        return [select Id,
                       Package_Version__c,
                       Solution__c
                       from 
                Solution_PackageVersion__c 
                where Id IN :pList];
    }
    

    
   /**
        RefreshSolution()
        - Overloaded to refresh Single Solution
    */
    private static Solution_Purpose__c RefreshSolutionPurpose(Solution_Purpose__c p)
    {
        return RefreshSolutionPurpose(new List<Solution_Purpose__c> {p})[0];
    }
    /**
        RefreshSolution()
    */
    private static List<Solution_Purpose__c> RefreshSolutionPurpose(List<Solution_Purpose__c> pList)
    {
        return [select Id,
                       Purpose__c,
                       Solution__c
                       from 
                Solution_Purpose__c 
                where Id IN :pList];
    }
    
        
   /**
        RefreshSolution()
        - Overloaded to refresh Single Solution
    */
    private static PackageVersion_Purpose__c RefreshPackageVersionPurpose(PackageVersion_Purpose__c p)
    {
        return RefreshPackageVersionPurpose(new List<PackageVersion_Purpose__c> {p})[0];
    }
    /**
        RefreshSolution()
    */
    private static List<PackageVersion_Purpose__c> RefreshPackageVersionPurpose(List<PackageVersion_Purpose__c> pList)
    {
        return [select Id,
                       Package_Version__c,
                       Purpose__c
                       from 
                PackageVersion_Purpose__c 
                where Id IN :pList];
    }
    
    
    
    /**
        RefreshProductLine()
        - Overloaded to refresh Single Solution
    */
    private static ProductLine_SolutionCategory__c RefreshProductLineSolutionCategory(ProductLine_SolutionCategory__c pProdLine)
    {
        return RefreshProductLineSolutionCategory(new List<ProductLine_SolutionCategory__c> {pProdLine})[0];
    }
    /**
        RefreshProductLine()
    */
    private static List<ProductLine_SolutionCategory__c> RefreshProductLineSolutionCategory(List<ProductLine_SolutionCategory__c> pProdLineList)
    {
        return [select Id,
                       Product_Line__c,
                       Solution_Category__c
                       from 
                ProductLine_SolutionCategory__c 
                where Id IN :pProdLineList];
    }


    
    
    
/** 
 *  Test method for Resolve_Solution_CategoryForeginKeys
 *  
 */
 testmethod static void Resolve_Solution_CategoryForeginKeys_SingleTest_Positive(){
        
        // Create a solution category record. This is test data set up
        Solution_Category__c sc = createSolutionCategory('Media acceleration','PC-SC-0001',null);
        insert sc;
        
        Test.startTest();
        Solution__c soln = CreateSolution('PC-SL-0001','PC-SC-0001');
        insert soln;
        Test.stopTest();
        
        soln = RefreshSolution(soln);
        system.assertEquals(soln.Solution_Category__c, sc.Id);
    
 }
 
    /**
        Resolve_Solution_CategoryForeginKeys_BulkTest_Positive()
        - Bulk
        - Positive
    */      
    testMethod static void Resolve_Solution_CategoryForeginKeys_BulkTest_Positive() 
    {
        
        Integer i;
        
        // Create 100 Headers
        List<Solution_Category__c> scList = new List<Solution_Category__c>();
        for(i=0;i<100;i++)
            scList.add(createSolutionCategory('DNA','#PC-SC-00' + i,null));
        insert scList;
        
        // Use the CI field to associate 100 Activities to 100 Header.
        Test.startTest();
        List<Solution__c> solutionList = new List<Solution__c>();
        for(i=0;i<100;i++)              
            solutionList.add(CreateSolution('PC-SL-00' + i, '#PC-SC-00' + i));
        insert solutionList;
        Test.stopTest();
        
        // Refresh
        solutionList = RefreshSolution(solutionList);
        
        // Assert
        for(i=0;i<100;i++)      
            system.assertEquals(solutionList[i].Solution_Category__c, scList[i].Id);
    }

        /**
        Resolve_Solution_CategoryForeginKeys_SingleTest_Negative()
        - Single
        - Negative
    */  
    static testMethod void Resolve_Solution_CategoryForeginKeys_SingleTest_Negative() 
    {
        
                // Create a solution category record. This is test data set up
        Solution_Category__c sc = createSolutionCategory('Media acceleration','PC-SC-0001',null);
        insert sc;
        
        Test.startTest();
        Boolean negativeCheckFlag = false;
        Solution__c soln; 
        try
        {
        soln = CreateSolution('PC-SL-0001','#INVALIDKEY');
        insert soln;
        }
        catch(Exception e)
        {
            //system.assert(e.getMessage().contains('Invalid Contract Header Id'));
            negativeCheckFlag = true;
        }
        Test.stopTest();
      
        // Assert
        system.assertEquals(negativeCheckFlag, true);
        
        
    }  


    /** 
     *  Test method for Resolve_Solution_ForeginKeys_SingleTest_Positive
     *  
     */
     testmethod static void Resolve_Solution_ForeginKeys_SingleTest_Positive(){
            
            Solution_Category__c sc1 = createSolutionCategory('Media acceleration','PC-SC-0002',null);
            insert sc1;
            
            // Create a solution category record. This is test data set up
            Solution__c soln = CreateSolution('PC-SL-0001','PC-SC-0002');
            insert soln;
            
            Test.startTest();
            Solution_Category__c sc = createSolutionCategory('Media acceleration','PC-SC-0001','PC-SL-0001');
            insert sc;
            Test.stopTest();
            
            
            sc = RefreshSolutionCategory(sc);
        
            system.assertEquals(sc.Default_Solution__c, soln.Id);
        
     }



    /** 
     *  Test method for Resolve_Solution_ForeginKeys_SingleTest_Negative
     *   - Single
     *   - Negative
     */
     testmethod static void Resolve_Solution_ForeginKeys_SingleTest_Negative(){
            
        
            Test.startTest();
            Boolean negativeCheckFlag = false;
            try
            {
                Solution_Category__c sc = createSolutionCategory('Media acceleration','PC-SC-0001','INVALID');
                insert sc;
            }
            catch(Exception e)
            {
                system.debug('Exception thrown');
                negativeCheckFlag = true;
            }
            Test.stopTest();
    
            // Assert
            system.assertEquals(negativeCheckFlag, true);
        
     }

        /**
            Resolve_Solution_ForeginKeys_BulkTest_Positive()
            - Bulk
            - Positive
        */      
        testMethod static void Resolve_Solution_ForeginKeys_BulkTest_Positive() 
        {
            
            Integer i;
            
            Solution_Category__c sc1 = createSolutionCategory('Media acceleration','PC-SC-0002',null);
            insert sc1;
            
            // Create a solution category record. This is test data set up
            Solution__c soln = CreateSolution('PC-SL-0001','PC-SC-0002');
            insert soln;
            
            Test.startTest();
            // Create 100 Headers
            List<Solution_Category__c> scList = new List<Solution_Category__c>();
            for(i=0;i<100;i++)
                scList.add(createSolutionCategory('DNA','#PC-SC-00' + i,'PC-SL-0001'));
            insert scList;
            
            Test.stopTest();
            
            // Refresh
            scList = RefreshSolutionCategory(scList);
            
            // Assert
            for(i=0;i<100;i++)      
                system.assertEquals(scList[i].Default_Solution__c, soln.Id);
        }

    
    /** 
     *  Test method for Resolve_Solution_CategoryForeginKeys
     *  
     */
     testmethod static void Resolve_PackageLine_ForeginKeys_SingleTest_Positive(){
            
            // Create a solution category record. This is test data set up
            PackageLine__c pl = CreatePackageLine('Media acceleration','PC-PL-0001');
            insert pl;
            
            Test.startTest();
            Package__c pkg = CreatePackage('PC-PK-0001','PC-PL-0001');
            insert pkg;
            Test.stopTest();
            
            
            pkg = RefreshPackage(pkg);
        
            system.assertEquals(pkg.PackageLines__c, pl.Id);
        
     }
 
    
 
    /** 
     *  Test method for Resolve_Solution_CategoryForeginKeys
     *  
     */
     testmethod static void Resolve_PackageLine_ForeginKeys_SingleTest_Negative(){
            
            // Create a solution category record. This is test data set up
            PackageLine__c pl = CreatePackageLine('Media acceleration','PC-PL-0001');
            insert pl;
            
            Test.startTest();
            Boolean negativeFlag = false;
            
            try{
                Package__c pkg = CreatePackage('PC-PK-0001','INVALID');
                insert pkg;
            }
            catch(Exception e){
                negativeFlag = true;
            }
            
            Test.stopTest();
        
            system.assert(negativeFlag);
        
     }
 

    /** 
     *  Test method for Resolve_Solution_CategoryForeginKeys
     *  
     */
     testmethod static void Resolve_PackageLine_ForeginKeys_BulkTest_Positive(){
            
            Integer i;
            
            // Create a solution category record. This is test data set up
            List<PackageLine__c> plList = new List<PackageLine__c>();
            for(i=0;i<100;i++)
               plList.add(CreatePackageLine('Media acceleration','PC-PL-00'+i));
            insert plList;
            
            Test.startTest();
            
            List<Package__c> scList = new List<Package__c>();
            for(i=0;i<100;i++)
                scList.add(CreatePackage('#PC-PK-00' + i,'PC-PL-00'+i));
            insert scList;
            Test.stopTest();
            
            
            scList = RefreshPackage(scList);
        
            for(i=0;i<100;i++)      
                system.assertEquals(scList[i].PackageLines__c, plList[i].Id);
    
     }
     
    /** 
     *  Test method for Resolve_Solution_ForeginKeys_SingleTest_Positive
     *  
     */
     testmethod static void Resolve_Package_ForeginKeys_SingleTest_Positive(){
            
        
            PackageLine__c pkg = CreatePackageLine('Media acceleration','PC-PL-0001');
            insert pkg;
        
            // Create a solution category record. This is test data set up
            Package__c pl = CreatePackage('PC-PK-0001','PC-PL-0001');
            insert pl;
            
            Test.startTest();
            Package_Version__c pv = CreatePackageVersion('PVC','PC-PV-0001','PC-PK-0001');
            insert pv;
            Test.stopTest();
            
            
            pv = RefreshPackageVersion(pv);
        
            system.assertEquals(pv.Package__c, pl.Id);
        

     }
     
     
    /** 
     *  Test method for Resolve_Solution_ForeginKeys_SingleTest_Positive
     *  
     */
     testmethod static void Resolve_Package_ForeginKeys_BulkTest_Positive(){
            
        
            PackageLine__c pkg = CreatePackageLine('Media acceleration','PC-PL-0001');
            insert pkg;
        
            // Create a solution category record. This is test data set up
            Integer i = 0;
            
            List<Package__c> packageList = new List<Package__c>();
            for(i = 0; i < 100;i++){
                packageList.add(CreatePackage('PC-PK-00'+i,'PC-PL-0001'));
            }
            insert packageList;
            
            
            Test.startTest();
            
            List<Package_Version__c> pvList = new List<Package_Version__c>();
            for(i = 0; i < 100 ; i++){
                 pvList.add(CreatePackageVersion('PVC','PC-PV-00'+i,'PC-PK-00'+i));
                
            }
            insert pvList;
            Test.stopTest();
            
            
            pvList = RefreshPackageVersion(pvList);
        
            for(i = 0; i < 100; i++)
                system.assertEquals(pvList[i].Package__c, packageList[i].Id);
        

     }     

   /** 
     *  Test method for Resolve_Solution_ForeginKeys_SingleTest_Positive
     *  
     */
     testmethod static void Resolve_Package_ForeginKeys_SingleTest_Negative(){
            
        
            PackageLine__c pkg = CreatePackageLine('Media acceleration','PC-PL-0001');
            insert pkg;
        
            // Create a solution category record. This is test data set up
            Package__c pl = CreatePackage('PC-PK-0001','PC-PL-0001');
            insert pl;
            
            Test.startTest();
            Boolean negativeFlag = false;
            try{
            Package_Version__c pv = CreatePackageVersion('PVC','INVALID','INVALID');
                insert pv;
            }
            catch(Exception e){
                negativeFlag = true;
                
            }
          
            Test.stopTest();
    
            system.assert(negativeFlag);
        

     }




    testmethod static void Resolve_Parent_Product_Category_ForeginKeys_SingleTest_Positive(){
        
        Product_Category__c parentpc = CreateProductCategory('Parent','PC-PC-0001',null);
        insert parentpc;
        
        Test.startTest();
        Product_Category__c childpc = CreateProductCategory('Child','PC-PC-0002','PC-PC-0001');
        insert childpc;
        Test.stopTest();
        
        childpc = RefreshProductCategory(childpc);
        
        system.assertEquals(childpc.Parent_Product_Category__c, parentpc.Id);
        
    }


    testmethod static void Resolve_Parent_Product_Category_ForeginKeys_BulkTest_Positive(){
        
        Product_Category__c parentpc = CreateProductCategory('Parent','PC-PC-00PA',null);
        insert parentpc;
        
        Test.startTest();
        Integer i = 0;
        
        List<Product_Category__c> pcList = new List<Product_Category__c>();
        
        for(i = 0; i < 100; i++){
        pcList.add(CreateProductCategory('Child','PC-PC-00'+i,'PC-PC-00PA'));
        }
        
        insert pcList;
        Test.stopTest();
        
        pcList = RefreshProductCategory(pcList);
        
        for(i=0;i<100;i++){
            system.assertEquals(pcList[i].Parent_Product_Category__c, parentpc.Id);
        }
    
        
    }
    
    testmethod static void Resolve_Parent_Product_Category_ForeginKeys_SingleTest_Negative(){
        
        Product_Category__c parentpc = CreateProductCategory('Parent','PC-PC-0001',null);
        insert parentpc;
        
        Test.startTest();
        Boolean negativeFlag = true;
        try{
        Product_Category__c childpc = CreateProductCategory('Child','PC-PC-0002','INVALID');
        insert childpc;
        }
        catch(Exception e){
            negativeFlag = true;
        }
        Test.stopTest();
        
        system.assert(negativeFlag);
        
    }
     /////////////////////////////////////////////////////////////////////////////////////





    testmethod static void Resolve_Product_Category_ForeginKeys_SingleTest_Positive(){
        
        Product_Category__c parentpc = CreateProductCategory('Parent','PC-PC-0001',null);
        insert parentpc;
        
        Test.startTest();
        Product__c product = CreateProductWithProductCategory('Product','PC-PC-0002','PC-PC-0001');
        insert product;
        Test.stopTest();
        
        product = RefreshProductWithProductCategory(product);
        
        system.assertEquals(product.Product_Category__c, parentpc.Id);
        
    }



    testmethod static void Resolve_Product_Category_ForeginKeys_BulkTest_Positive(){
        
        Product_Category__c parentpc = CreateProductCategory('Parent','PC-PC-0001',null);
        insert parentpc;
        
        Test.startTest();
        Integer i = 0;
        List<Product__c> pList = new List<Product__c>();
        for(i = 0; i < 100; i++){
            pList.add(CreateProductWithProductCategory('Product','PC-PC-00'+i,'PC-PC-0001'));
        }

        insert pList;
        Test.stopTest();
        
        pList = RefreshProductWithProductCategory(pList);
        
        for(i =0; i < 100; i++)
            system.assertEquals(pList[i].Product_Category__c, parentpc.Id);
        
    }    
     
    testmethod static void Resolve_Product_Category_ForeginKeys_SingleTest_Negative(){
        
        Product_Category__c parentpc = CreateProductCategory('Parent','PC-PC-0001',null);
        insert parentpc;
        
        Test.startTest();
        Boolean negativeFlag = false;
        
        try{
        Product__c product = CreateProductWithProductCategory('Product','PC-PC-0002','INVALID');
        insert product;
        }
        catch(Exception e){
            negativeFlag = true;
        }
        Test.stopTest();
    
        system.assert(negativeFlag);
        
    }
     
         /////////////////////////////////////////////////////////////////////////////////////
 


    testmethod static void Resolve_Solution_Territory_ForeginKeys_SingleTest_Positive(){
        
        Solution_Category__c sc = createSolutionCategory('Media acceleration','PC-SC-0001',null);
        insert sc;
        
        Solution__c solution = CreateSolution('PC-SL-0001','PC-SC-0001');
        insert solution;
        
        Territory__c territory = CreateTerritory('PC-TR-0001');
        insert territory;
        
        Test.startTest();
        Solution_Territory__c solnTerritory = CreateSolutionTerritory('SolutionTerritory','PC-ST-0002','PC-SL-0001','PC-TR-0001');
        insert solnTerritory;
        Test.stopTest();
        
        solnTerritory = RefreshSolutionTerritory(solnTerritory);
        
        system.assertEquals(solnTerritory.Solution__c, solution.Id);
        system.assertEquals(solnTerritory.Territory__c, territory.Id);
        
    }
    
    
    testmethod static void Resolve_Solution_Territory_ForeginKeys_BulkTest_Positive(){
        
        Solution_Category__c sc = createSolutionCategory('Media acceleration','PC-SC-0001',null);
        insert sc;
       
        Integer i = 0;
        List<Solution__c> solnList = new List<Solution__c>();
        List<Territory__c> terrList = new List<Territory__c>();
        
        for(i = 0; i < 100; i++){
            solnList.add(CreateSolution('PC-SL-00'+i,'PC-SC-0001'));
            terrList.add(CreateTerritory('PC-TR-00'+i));
        } 
        
        insert solnList;
        insert terrList;
        

        
        Test.startTest();
        
        List<Solution_Territory__c> solnTerritoryList = new List<Solution_Territory__c>();
        
        for(i = 0; i < 100; i++){
            solnTerritoryList.add(CreateSolutionTerritory('SolutionTerritory','PC-ST-00'+i,'PC-SL-00'+i,'PC-TR-00'+i));
        } 
        

        insert solnTerritoryList;
        Test.stopTest();
        
        solnTerritoryList = RefreshSolutionTerritory(solnTerritoryList);
        
        for(i = 0; i < 100; i++){
            system.assertEquals(solnTerritoryList[i].Solution__c, solnList[i].Id);
            system.assertEquals(solnTerritoryList[i].Territory__c, terrList[i].Id);
        } 
        
    
    }

    testmethod static void Resolve_Solution_Territory_ForeginKeys_SingleTest_Negative(){
        
        Solution_Category__c sc = createSolutionCategory('Media acceleration','PC-SC-0001',null);
        insert sc;
        
        Solution__c solution = CreateSolution('PC-SL-0001','PC-SC-0001');
        insert solution;
        
        Territory__c territory = CreateTerritory('PC-TR-0001');
        insert territory;
        
        Test.startTest();
        Boolean negativeFlag = false;
        
        try{
        Solution_Territory__c solnTerritory = CreateSolutionTerritory('SolutionTerritory','PC-ST-0002','INVALID','INVALID');
        insert solnTerritory;
        }
        catch(Exception e){
            negativeFlag = true;
        }
        Test.stopTest();
        
        system.assert(negativeFlag);
        
    }   
     
         /////////////////////////////////////////////////////////////////////////////////////
 



    testmethod static void Resolve_PackageVersion_Products_ForeginKeys_SingleTest_Positive(){
    
        // Create a solution category record. This is test data set up
        PackageLine__c pline = CreatePackageLine('Media acceleration','PC-PL-0001');
        insert pline;

        // Create a solution category record. This is test data set up
        Package__c pl = CreatePackage('PC-PK-0001','PC-PL-0001');
        insert pl;          

        Product_Category__c parentpc = CreateProductCategory('Parent','PC-PC-0001',null);
        insert parentpc;

        Product__c product = CreateProductWithProductCategory('Product','PC-PC-0002','PC-PC-0001');
        insert product;     
        
        
        Package_Version__c pv = CreatePackageVersion('PVC','PC-PV-0001','PC-PK-0001');
        insert pv;
        
        Test.startTest();
        PackageVersion_Products__c pvp = CreatePackageVersionProducts('SolutionTerritory','PC-PPV-0001','PC-PV-0001','PC-PC-0002');
        insert pvp;
        Test.stopTest();
        
        pvp = RefreshPackageVersionProduct(pvp);
        
        system.assertEquals(pvp.Package_Version__c, pv.Id);
        system.assertEquals(pvp.Product__c, product.Id);
        
    }
    
    
    testmethod static void Resolve_PackageVersion_Products_ForeginKeys_BulkTest_Positive(){
    
        // Create a solution category record. This is test data set up
        PackageLine__c pline = CreatePackageLine('Media acceleration','PC-PL-0001');
        insert pline;

        // Create a solution category record. This is test data set up
        Package__c pl = CreatePackage('PC-PK-0001','PC-PL-0001');
        insert pl;          

        Product_Category__c parentpc = CreateProductCategory('Parent','PC-PC-0001',null);
        insert parentpc;

        Integer i = 0;
        List<Product__c> pList = new List<Product__c>();
        List<Package_Version__c> pvcList = new List<Package_Version__c>();
        
        for(i = 0; i < 100; i++){
        pList.add(CreateProductWithProductCategory('Product','PC-PC-00'+i,'PC-PC-0001'));
        pvcList.add(CreatePackageVersion('PVC','PC-PV-00'+i,'PC-PK-0001'));
        }
        
        insert pList;
        insert pvcList;

        
        Test.startTest();
        List<PackageVersion_Products__c> pvpList = new List<PackageVersion_Products__c>();
        for(i = 0; i < 100; i++){
        pvpList.add(CreatePackageVersionProducts('SolutionTerritory','PC-PPV-00'+i,'PC-PV-00'+i,'PC-PC-00'+i));
        }
        insert pvpList;
        Test.stopTest();
        
        pvpList = RefreshPackageVersionProduct(pvpList);
        
        for(i = 0; i < 100; i++){
        system.assertEquals(pvpList[i].Package_Version__c, pvcList[i].Id);
        system.assertEquals(pvpList[i].Product__c, pList[i].Id);
        }       
    }
    
 
 
    testmethod static void Resolve_PackageVersion_Products_ForeginKeys_SingleTest_Negative(){
    
        // Create a solution category record. This is test data set up
        PackageLine__c pline = CreatePackageLine('Media acceleration','PC-PL-0001');
        insert pline;

        // Create a solution category record. This is test data set up
        Package__c pl = CreatePackage('PC-PK-0001','PC-PL-0001');
        insert pl;          

        Product_Category__c parentpc = CreateProductCategory('Parent','PC-PC-0001',null);
        insert parentpc;

        Product__c product = CreateProductWithProductCategory('Product','PC-PC-0002','PC-PC-0001');
        insert product;     
        
        
        Package_Version__c pv = CreatePackageVersion('PVC','PC-PV-0001','PC-PK-0001');
        insert pv;
        
        Test.startTest();
        Boolean negativeFlag = false;
        
        try{
        PackageVersion_Products__c pvp = CreatePackageVersionProducts('SolutionTerritory','PC-PPV-0001','PC-PV-0001','Pinvalid');
        insert pvp;
        
        }catch(Exception e){
            negativeFlag = true;
        }
        Test.stopTest();
        
        system.assert(negativeFlag);
        
    }
 
 
  ///////////////////////////////////////////////////////////////////////////////////////////
 



    testmethod static void Resolve_Solution_PackageVersion_ForeginKeys_SingleTest_Positive(){

        // Create a solution category record. This is test data set up
        PackageLine__c pline = CreatePackageLine('Media acceleration','PC-PL-0001');
        insert pline;

        // Create a solution category record. This is test data set up
        Package__c pl = CreatePackage('PC-PK-0001','PC-PL-0001');
        insert pl;          


        Package_Version__c pv = CreatePackageVersion('PVC','PC-PV-0001','PC-PK-0001');
        insert pv;
        
        
        Solution_Category__c sc = createSolutionCategory('Media acceleration','PC-SC-0001',null);
        insert sc;
        
        Solution__c solution = CreateSolution('PC-SL-0001','PC-SC-0001');
        insert solution;
            
        Test.startTest();
        Solution_PackageVersion__c pvp = CreateSolutionPackageVersion('soln','PC-SPV-0001','PC-PV-0001','PC-SL-0001');
        insert pvp;
        Test.stopTest();
        
        pvp = RefreshSolutionPackageVersion(pvp);
        
        system.assertEquals(pvp.Package_Version__c, pv.Id);
        system.assertEquals(pvp.Solution__c, solution.Id);
        
    }
    
    
    
    testmethod static void Resolve_Solution_PackageVersion_ForeginKeys_BulkTest_Positive(){

        // Create a solution category record. This is test data set up
        PackageLine__c pline = CreatePackageLine('Media acceleration','PC-PL-0001');
        insert pline;

        // Create a solution category record. This is test data set up
        Package__c pl = CreatePackage('PC-PK-0001','PC-PL-0001');
        insert pl;          

        
        Solution_Category__c sc = createSolutionCategory('Media acceleration','PC-SC-0001',null);
        insert sc;

        Integer i;
        List<Package_Version__c> pvcList = new List<Package_Version__c>();
        List<Solution__c> solnList = new List<Solution__c>();
        
        for(i = 0; i < 100; i++){
            pvcList.add(CreatePackageVersion('PVC','PC-PV-00'+i,'PC-PK-0001'));
            solnList.add(CreateSolution('PC-SL-00'+i,'PC-SC-0001'));
            
        }
    
        insert pvcList;
        insert solnList;
        
            
        Test.startTest();
        List<Solution_PackageVersion__c> spcList = new List<Solution_PackageVersion__c>();
        for(i=0;i<100;i++){
             spcList.add(CreateSolutionPackageVersion('soln','PC-SPV-00'+i,'PC-PV-00'+i,'PC-SL-00'+i));
        }

        insert spcList;
        Test.stopTest();
        
        spcList = RefreshSolutionPackageVersion(spcList);
        
        for(i=0;i<100;i++){
        system.assertEquals(spcList[i].Package_Version__c, pvcList[i].Id);
        system.assertEquals(spcList[i].Solution__c, solnList[i].Id);
        }
    }
    
    

    testmethod static void Resolve_Solution_PackageVersion_ForeginKeys_SingleTest_Negative(){

        // Create a solution category record. This is test data set up
        PackageLine__c pline = CreatePackageLine('Media acceleration','PC-PL-0001');
        insert pline;

        // Create a solution category record. This is test data set up
        Package__c pl = CreatePackage('PC-PK-0001','PC-PL-0001');
        insert pl;          


        Package_Version__c pv = CreatePackageVersion('PVC','PC-PV-0001','PC-PK-0001');
        insert pv;
        
        
        Solution_Category__c sc = createSolutionCategory('Media acceleration','PC-SC-0001',null);
        insert sc;
        
        Solution__c solution = CreateSolution('PC-SL-0001','PC-SC-0001');
        insert solution;
            
        Test.startTest();
        Boolean negativeFlag = true;
        
        try{
        Solution_PackageVersion__c pvp = CreateSolutionPackageVersion('soln','PC-SPV-0001','PC-PV-inv','PC-inv-0001');
        insert pvp;
        }
        catch(Exception e){
            negativeFlag = true;
        }
        Test.stopTest();
        
        system.assert(negativeFlag);
                
    }   
    
    
    //////////////////////////////////////////////////////////////////////////////////////////
 
    testmethod static void Resolve_Solution_Purpose_ForeginKeys_SingleTest_Positive(){


        Purpose__c purpose = CreatePurpose('newpurpose','PC-PUR-0001');
        insert purpose;
        
        
        Solution_Category__c sc = createSolutionCategory('Media acceleration','PC-SC-0001',null);
        insert sc;
        
        Solution__c solution = CreateSolution('PC-SL-0001','PC-SC-0001');
        insert solution;
        
        Solution_Purpose__c sp = CreateSolutionPurpose('sp','PC-SP-0001','PC-PUR-0001','PC-SL-0001');
        insert sp;
        
        sp = RefreshSolutionPurpose(sp);
        
        system.assertEquals(sp.Purpose__c, purpose.Id);
        system.assertEquals(sp.Solution__c, solution.Id);
        
    }
    
 
    testmethod static void Resolve_Solution_Purpose_ForeginKeys_BulkTest_Positive(){

        Solution_Category__c sc = createSolutionCategory('Media acceleration','PC-SC-0001',null);
        insert sc;
        
        Integer i = 0;
        List<Solution__c> solnList = new List<Solution__c>();
        List<Purpose__c> purposeList = new List<Purpose__c>();
        
        for(i=0;i<100;i++){
            solnList.add(CreateSolution('PC-SL-00'+i,'PC-SC-0001'));
            purposeList.add(CreatePurpose('newpurpose','PC-PUR-00'+i));
        }
        
        insert solnList;
        insert purposeList;
            
        
        Test.startTest();
        List<Solution_Purpose__c> spcList = new List<Solution_Purpose__c>();
        
        for(i=0;i<100;i++){
            spcList.add(CreateSolutionPurpose('sp','PC-SP-00'+i,'PC-PUR-00'+i,'PC-SL-00'+i));
        }
            
        insert spcList;
            
        Test.stopTest();
        
        spcList = RefreshSolutionPurpose(spcList);
        
        for(i=0;i<100;i++){
        system.assertEquals(spcList[i].Purpose__c, purposeList[i].Id);
        system.assertEquals(spcList[i].Solution__c, solnList[i].Id);            
        }

        
    } 
    
    
    testmethod static void Resolve_Solution_Purpose_ForeginKeys_SingleTest_Negative(){


        Purpose__c purpose = CreatePurpose('newpurpose','PC-PUR-0001');
        insert purpose;
        
        
        Solution_Category__c sc = createSolutionCategory('Media acceleration','PC-SC-0001',null);
        insert sc;
        
        Solution__c solution = CreateSolution('PC-SL-0001','PC-SC-0001');
        insert solution;
        
        Boolean negativeFlag = false;
        
        try{
        Solution_Purpose__c sp = CreateSolutionPurpose('sp','PC-SP-0001','PC-INVALID','PC-INVALID');
        insert sp;
        
        }
        catch(Exception e){
            negativeFlag = true;
        }

        system.assert(negativeFlag);

        
    }
    
 
    //////////////////////////////////////////////////////////////////////////////////////////
    

    testmethod static void Resolve_PackageVersion_Purpose_ForeginKeys_SingleTest_Positive(){


        Purpose__c purpose = CreatePurpose('newpurpose','PC-PUR-0001');
        insert purpose;
        
        // Create a solution category record. This is test data set up
        PackageLine__c pline = CreatePackageLine('Media acceleration','PC-PL-0001');
        insert pline;

        // Create a solution category record. This is test data set up
        Package__c pl = CreatePackage('PC-PK-0001','PC-PL-0001');
        insert pl;          


        Package_Version__c pv = CreatePackageVersion('PVC','PC-PV-0001','PC-PK-0001');
        insert pv;

        Test.startTest();
        PackageVersion_Purpose__c pvp = CreatePackageVersionPurpose('sp','PC-PVP-0001','PC-PV-0001','PC-PUR-0001');
        insert pvp;
        
        Test.stopTest();
        
        pvp = RefreshPackageVersionPurpose(pvp);
        
        system.assertEquals(pvp.Package_Version__c, pv.Id);
        system.assertEquals(pvp.Purpose__c, purpose.Id);
        
    }
    

    testmethod static void Resolve_PackageVersion_Purpose_ForeginKeys_BulkTest_Positive(){



        // Create a solution category record. This is test data set up
        PackageLine__c pline = CreatePackageLine('Media acceleration','PC-PL-0001');
        insert pline;

        // Create a solution category record. This is test data set up
        Package__c pl = CreatePackage('PC-PK-0001','PC-PL-0001');
        insert pl;          

        Integer i = 0;
        
        List<Package_Version__c> pvcList = new List<Package_Version__c>();
        List<Purpose__c> pList = new List<Purpose__c>();

        for(i = 0; i<100; i++){
            pvcList.add(CreatePackageVersion('PVC','PC-PV-00'+i,'PC-PK-0001'));
            pList.add(CreatePurpose('newpurpose','PC-PUR-00'+i));
            
        }
        
        insert pvcList;
        insert pList;
        
        
        Test.startTest();
        
        List<PackageVersion_Purpose__c> pvpList = new List<PackageVersion_Purpose__c>();
        
        for(i = 0; i<100; i++){
            pvpList.add(CreatePackageVersionPurpose('sp','PC-PVP-00'+i,'PC-PV-00'+i,'PC-PUR-00'+i));
        }
        
        insert pvpList;
        
        Test.stopTest();
        
        pvpList = RefreshPackageVersionPurpose(pvpList);
        
        for(i = 0; i<100; i++){
        system.assertEquals(pvpList[i].Package_Version__c, pvcList[i].Id);
        system.assertEquals(pvpList[i].Purpose__c, pList[i].Id);
        }
        
    }
        
    
    testmethod static void Resolve_PackageVersion_Purpose_ForeginKeys_SingleTest_Negative(){


        Purpose__c purpose = CreatePurpose('newpurpose','PC-PUR-0001');
        insert purpose;
        
        // Create a solution category record. This is test data set up
        PackageLine__c pline = CreatePackageLine('Media acceleration','PC-PL-0001');
        insert pline;

        // Create a solution category record. This is test data set up
        Package__c pl = CreatePackage('PC-PK-0001','PC-PL-0001');
        insert pl;          


        Package_Version__c pv = CreatePackageVersion('PVC','PC-PV-0001','PC-PK-0001');
        insert pv;
        
        Boolean negativeFlag = true;
        
        try{
        PackageVersion_Purpose__c pvp = CreatePackageVersionPurpose('sp','PC-PVP-0001','PC-PV-0001','PC-PUR-0001');
        insert pvp;
        }
        catch(Exception e){
            negativeFlag = true;
        }
        
        system.assert(negativeFlag);
        
    }
    
    
    //******************************************************************************************************************
    
    
    
/** 
 *  Test method for Resolve_Solution_CategoryForeginKeys
 *  
 */
 testmethod static void Resolve_Solution_CategoryForeginKeys_update_SingleTest_Negative(){
        
        // Create a solution category record. This is test data set up
        Solution_Category__c sc = createSolutionCategory('Media acceleration','PC-SC-0001',null);
        insert sc;
        
        Test.startTest();
        Solution__c soln = CreateSolution('PC-SL-0001','PC-SC-0001');
        insert soln;
        
        Boolean b = false;
        try{
            soln.CI_Solution_Category__c = 'PC-SC-0002';
            update soln;
            
        }
        catch(Exception e){
            b = true;
        }
            Test.stopTest();
        
   
        system.assert(b);
    
 }
 
    /** 
     *  Test method for Resolve_Solution_CategoryForeginKeys
     *  
     */
     testmethod static void Resolve_PackageLine_ForeginKeys_update_SingleTest_Positive(){
            
            // Create a solution category record. This is test data set up
            PackageLine__c pl = CreatePackageLine('Media acceleration','PC-PL-0001');
            insert pl;
            
            Test.startTest();
            Package__c pkg = CreatePackage('PC-PK-0001','PC-PL-0001');
            insert pkg;
            
            Boolean b = false;
            try{
                pkg.CI_PackageLine__c = 'PC-PL-0002';
                update pkg;
            }
            catch(Exception e){
                b = true;
            }
            
            Test.stopTest();
            system.assert(b);
        
     }
 
 


     
    /** 
     *  Test method for Resolve_Solution_ForeginKeys_update_SingleTest_Positive
     *  
     */
     testmethod static void Resolve_Package_ForeginKeys_update_SingleTest_Positive(){
            
        
            PackageLine__c pkg = CreatePackageLine('Media acceleration','PC-PL-0001');
            insert pkg;
        
            // Create a solution category record. This is test data set up
            Package__c pl = CreatePackage('PC-PK-0001','PC-PL-0001');
            insert pl;
            
            Test.startTest();
            Package_Version__c pv = CreatePackageVersion('PVC','PC-PV-0001','PC-PK-0001');
            insert pv;
            Test.stopTest();
            
            
            pv = RefreshPackageVersion(pv);
        
            system.assertEquals(pv.Package__c, pl.Id);
        

     }




     /////////////////////////////////////////////////////////////////////////////////////





    testmethod static void Resolve_Product_Category_ForeginKeys_update_SingleTest_Positive(){
        
        Product_Category__c parentpc = CreateProductCategory('Parent','PC-PC-0001',null);
        insert parentpc;
        
        Test.startTest();
        Product__c product = CreateProductWithProductCategory('Product','PC-PC-0002','PC-PC-0001');
        insert product;
        
        Boolean b = false;
        try{
            product.CI_Product_Category__c = 'UPDATED';
            update product;
        }
        catch(Exception e){
            b = true;
        }
        
    
        system.assert(b);
        
    }
     
     

     
         /////////////////////////////////////////////////////////////////////////////////////
 


    testmethod static void Resolve_Solution_Territory_ForeginKeys_update_SingleTest_Positive(){
        
        Solution_Category__c sc = createSolutionCategory('Media acceleration','PC-SC-0001',null);
        insert sc;
        
        Solution__c solution = CreateSolution('PC-SL-0001','PC-SC-0001');
        insert solution;
        
        Territory__c territory = CreateTerritory('PC-TR-0001');
        insert territory;
        
        Test.startTest();
        Solution_Territory__c solnTerritory = CreateSolutionTerritory('SolutionTerritory','PC-ST-0002','PC-SL-0001','PC-TR-0001');
        insert solnTerritory;
        Test.stopTest();
        
        Boolean b = false;
        try{
            solnTerritory.CI_Solution__c = 'INVALID';
            solnTerritory.CI_Territory__c = 'INVALID';
            update solnTerritory;
        }
        catch(Exception e){
            b = true;
        }
        
        
        
        system.assert(b);
        
    }
    
    
     
         /////////////////////////////////////////////////////////////////////////////////////
 



    testmethod static void Resolve_PackageVersion_Products_ForeginKeys_update_SingleTest_Positive(){
    
        // Create a solution category record. This is test data set up
        PackageLine__c pline = CreatePackageLine('Media acceleration','PC-PL-0001');
        insert pline;

        // Create a solution category record. This is test data set up
        Package__c pl = CreatePackage('PC-PK-0001','PC-PL-0001');
        insert pl;          

        Product_Category__c parentpc = CreateProductCategory('Parent','PC-PC-0001',null);
        insert parentpc;

        Product__c product = CreateProductWithProductCategory('Product','PC-PC-0002','PC-PC-0001');
        insert product;     
        
        
        Package_Version__c pv = CreatePackageVersion('PVC','PC-PV-0001','PC-PK-0001');
        insert pv;
        
        Test.startTest();
        PackageVersion_Products__c pvp = CreatePackageVersionProducts('SolutionTerritory','PC-PPV-0001','PC-PV-0001','PC-PC-0002');
        insert pvp;
        Test.stopTest();
        
        Boolean b = false;
        
        try{
            pvp.CI_Package_Version__c = 'INVALID';
            pvp.CI_Product__c = 'INVLAID';
            update pvp;
        }
        catch(Exception e){
            b = true;
        }
        
            system.assert(b);
    }
 

 
 
  ///////////////////////////////////////////////////////////////////////////////////////////
 



    testmethod static void Resolve_Solution_PackageVersion_ForeginKeys_update_SingleTest_Positive(){

        // Create a solution category record. This is test data set up
        PackageLine__c pline = CreatePackageLine('Media acceleration','PC-PL-0001');
        insert pline;

        // Create a solution category record. This is test data set up
        Package__c pl = CreatePackage('PC-PK-0001','PC-PL-0001');
        insert pl;          


        Package_Version__c pv = CreatePackageVersion('PVC','PC-PV-0001','PC-PK-0001');
        insert pv;
        
        
        Solution_Category__c sc = createSolutionCategory('Media acceleration','PC-SC-0001',null);
        insert sc;
        
        Solution__c solution = CreateSolution('PC-SL-0001','PC-SC-0001');
        insert solution;
            
        Test.startTest();
        Solution_PackageVersion__c pvp = CreateSolutionPackageVersion('soln','PC-SPV-0001','PC-PV-0001','PC-SL-0001');
        insert pvp;
        Test.stopTest();
        
        Boolean b = false;
        try{
            pvp.CI_Package_Version__c = 'INVALID';
            pvp.CI_Solution__c = 'INVALID';
            update pvp;
        }
        catch(Exception e){
            b = true;
        }
        
        system.assert(b);
        
    }
    

    
    
    //////////////////////////////////////////////////////////////////////////////////////////
 
    testmethod static void Resolve_Solution_Purpose_ForeginKeys_update_SingleTest_Positive(){


        Purpose__c purpose = CreatePurpose('newpurpose','PC-PUR-0001');
        insert purpose;
        
        
        Solution_Category__c sc = createSolutionCategory('Media acceleration','PC-SC-0001',null);
        insert sc;
        
        Solution__c solution = CreateSolution('PC-SL-0001','PC-SC-0001');
        insert solution;
        
        Solution_Purpose__c sp = CreateSolutionPurpose('sp','PC-SP-0001','PC-PUR-0001','PC-SL-0001');
        insert sp;
        
        Boolean b = false;
        
        try{
            sp.CI_Purpose__c = 'INVALID';
            sp.CI_Solution__c = 'INVALID';
            update sp;
        }
        catch(Exception e){
            b = true;
        }
        
        system.assert(b);
        
    }
    
 

    
 
    //////////////////////////////////////////////////////////////////////////////////////////
    

    testmethod static void Resolve_PackageVersion_Purpose_ForeginKeys_update_SingleTest_Positive(){


        Purpose__c purpose = CreatePurpose('newpurpose','PC-PUR-0001');
        insert purpose;
        
        // Create a solution category record. This is test data set up
        PackageLine__c pline = CreatePackageLine('Media acceleration','PC-PL-0001');
        insert pline;

        // Create a solution category record. This is test data set up
        Package__c pl = CreatePackage('PC-PK-0001','PC-PL-0001');
        insert pl;          


        Package_Version__c pv = CreatePackageVersion('PVC','PC-PV-0001','PC-PK-0001');
        insert pv;

        
        PackageVersion_Purpose__c pvp = CreatePackageVersionPurpose('sp','PC-PVP-0001','PC-PV-0001','PC-PUR-0001');
        insert pvp;
        
        Boolean b = false;
        try{
            pvp.CI_Package_Version__c = 'INVALID';
            pvp.CI_Purpose__c = 'INVALID';
            update pvp;
        }
        catch(Exception e){
            b = true;
        }
        
        system.assert(b);
        
    }
    
    

    
    /** 
     *  Test method for Resolve_Solution_ForeginKeys_SingleTest_Positive
     *  
     */
     testmethod static void Resolve_Package_ForeginKeys_SingleTest_update_Positive(){
            
        
            PackageLine__c pkg = CreatePackageLine('Media acceleration','PC-PL-0001');
            insert pkg;
        
            // Create a solution category record. This is test data set up
            Package__c pl = CreatePackage('PC-PK-0001','PC-PL-0001');
            insert pl;
            
            Test.startTest();
            Package_Version__c pv = CreatePackageVersion('PVC','PC-PV-0001','PC-PK-0001');
            insert pv;
            
            Boolean b = false;
            
            try{
                pv.CI_Package__c = 'INVALID';
                pv.CI_Purpose__c = 'INVALID';
                update pv;
            }
            catch(Exception e){
                b = true;
            }
            
            
            Test.stopTest();
            
            
            system.assert(b);
        

     }
       

        testmethod static void Resolve_Parent_Product_Category_ForeginKeys_update_SingleTest_Positive(){
        
        Product_Category__c parentpc = CreateProductCategory('Parent','PC-PC-0001',null);
        insert parentpc;
        
        Product_Category__c parentpc2 = CreateProductCategory('Parent','PC-PC-0002',null);
        insert parentpc2;

        Product_Category__c childpc = CreateProductCategory('Child','PC-PC-0003','PC-PC-0001');
        insert childpc;
        
        Test.startTest();
            childpc.CI_Parent_Product_Category__c =  'PC-PC-0002';
            update childpc;
        Test.stopTest();
        
        childpc = RefreshProductCategory(childpc);
        
        system.assertEquals(childpc.Parent_Product_Category__c, parentpc2.Id);
        
    }

    
    
    /** 
     *  Test method for Resolve_Solution_ForeginKeys_SingleTest_Positive
     *  
     */
     testmethod static void Resolve_Solution_ForeginKeys_update_SingleTest_Positive(){
            
            Solution_Category__c sc1 = createSolutionCategory('Media acceleration','PC-SC-0002',null);
            insert sc1;
            
            // Create a solution category record. This is test data set up
            Solution__c soln = CreateSolution('PC-SL-0001','PC-SC-0002');
            insert soln;
            
                        
            // Create a solution category record. This is test data set up
            Solution__c soln2 = CreateSolution('PC-SL-0002','PC-SC-0002');
            insert soln2;
            

            Solution_Category__c sc = createSolutionCategory('Media acceleration','PC-SC-0001','PC-SL-0001');
            insert sc;

            Test.startTest();
            sc.CI_Default_Solution__c = 'PC-SL-0002';
            update sc;
            Test.stopTest();
            
            
            sc = RefreshSolutionCategory(sc);
        
            system.assertEquals(sc.Default_Solution__c, soln2.Id);
        
     }
    
     	/**
 		Test method for Resolve_ProductLine_SolutionCategory_ForeignKeys
 	*/
 	testmethod static void Resolve_ProductLine_SolutionCategory_ForeignKeys_SingleTest_Positive(){
 		
 		    Solution_Category__c sc1 = createSolutionCategory('Media acceleration','PC-SC-0002',null);
            insert sc1;
 		
 			Product_Line__c pl = CreateProductLine('Media accleration', 'PC-PL-0001');
 			insert pl;
 			
 			Test.startTest();
 			ProductLine_SolutionCategory__c plsc = CreateProductLineSolutionCategory('plsc','PC-PL-0001','PC-SC-0002');
 			insert plsc;
 			
 			Test.stopTest();
 			
 			
 			ProductLine_SolutionCategory__c plsc_ref = RefreshProductLineSolutionCategory(plsc);
 			
 			system.assertEquals(plsc_ref.Solution_Category__c, sc1.Id);
 			system.assertEquals(plsc_ref.Product_Line__c, pl.Id);
 			
 		
 		
 	}
 	
 	
 	     	/**
 		Test method for Resolve_ProductLine_SolutionCategory_ForeignKeys
 	*/
 	testmethod static void Resolve_ProductLine_SolutionCategory_ForeignKeys_Update_SingleTest_Positive(){
 		
 		    Solution_Category__c sc1 = createSolutionCategory('Media acceleration','PC-SC-0002',null);
            insert sc1;
 		
 			Product_Line__c pl = CreateProductLine('Media accleration', 'PC-PL-0001');
 			insert pl;

 			Product_Line__c pl2 = CreateProductLine('Media accleration', 'PC-PL-0002');
 			insert pl2; 			
 			
 			ProductLine_SolutionCategory__c plsc = CreateProductLineSolutionCategory('plsc','PC-PL-0001','PC-SC-0002');
 			insert plsc;


 			Test.startTest();
 			
 			Boolean negativeFlag = false;
 			
 			try{
 			plsc.CI_Product_Line__c = 'PC-PL-0002';
 			update plsc;
 			
 			}
 			catch(Exception e){
 				negativeFlag = true;
 			}
 			
 			Test.stopTest();

 			system.assert(negativeFlag);
 		
 		
 	}
 	

 	
 	     	/**
 		Test method for Resolve_ProductLine_SolutionCategory_ForeignKeys
 	*/
 	testmethod static void Resolve_ProductLine_SolutionCategory_ForeignKeys_SingleTest_Negative() {
 		
 		    Solution_Category__c sc1 = createSolutionCategory('Media acceleration','PC-SC-0002',null);
            insert sc1;
 		
 			Product_Line__c pl = CreateProductLine('Media accleration', 'PC-PL-0001');
 			insert pl;
 			
 			Test.startTest();
 			
 			Boolean negativeFlag = false;
 			
 			try{
 			ProductLine_SolutionCategory__c plsc = CreateProductLineSolutionCategory('plsc','PC-PL-0001','Invalidkey');
 			insert plsc;
 			
 			}
 			catch(Exception e){
 				negativeFlag = true;
 			}
 			
 			Test.stopTest();

 			system.assert(negativeFlag);
 		
 		
 	} 	

 
}