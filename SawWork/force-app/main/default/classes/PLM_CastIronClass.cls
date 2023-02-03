/***
	PLM_CastIronClass
    @author : Yogesh Gupta <yogupta@akamai.com>
    @Description : This class is used to resolve foreign key relationships during Cast Iron Integration.
    			   The design is :
    			   1. Cast Iron sets the AKAM Id in a "CI_%" field.
    			   2. The logic in this class will lookup the corresponding object and fetch the Salesforce ID.
    			   3. The logic in this class will then set the Lookup according to the fetched value in Step 2.
    			   
    			   Currently, the following keys are resolved :
    			   1. Solution - SolutionCategory
    			   2. SolutionCategory - DefaultSolution
    			   3. Package - PackageLine
    			   4. PackageVersion - Package
    			   5. ProductCategory - Parent ProductCategory
    			   6. Product - ProductCategory
    			   7. Solution - Territory
    			   8. PackageVersion - Product
    			   9. Solution - PackageVersion
    			   10. Solution - Purpose
    			   11. PackageVersion - Purpose

*/
global class PLM_CastIronClass 
{
	
	public static boolean firstRun = true; 
	/**
	1. Resolve_Solution_CategoryForeginKeys()
	- Resolved the Foreign Key relation of the field Solution__c.Solution_Category__c via field Solution__c.CI_Solution_Category__c
	*/
	public static void Resolve_Solution_CategoryForeginKeys(Solution__c[] solutions)
	{
		// Form a Set
		Set<String> solCategoryAkamIdSet = new Set<String>();
		for(Solution__c sol : solutions)
			solCategoryAkamIdSet.add(sol.CI_Solution_Category__c);
	
		// Query and Create a Map
		Map<String, Id> solCatIdIdMap = new Map<String, Id>();
		for(Solution_Category__c solCategory : [select Id, AKAM_Solution_Category_Id__c from Solution_Category__c where AKAM_Solution_Category_Id__c IN :solCategoryAkamIdSet])
			solCatIdIdMap.put(solCategory.AKAM_Solution_Category_Id__c, solCategory.Id);
	
		// Make the Update
		for(Solution__c sol : solutions)
		{
			sol.Solution_Category__c = solCatIdIdMap.get(sol.CI_Solution_Category__c);
			if(sol.CI_Solution_Category__c != '' && sol.Solution_Category__c == null)
				sol.addError('Invalid Solution Category Id : ' + sol.CI_Solution_Category__c);
		}
	}
	
	/**
	2. Resolve_Solution_ForeginKeys()
	- Resolved the Foreign Key relation of the field Solution_Category__c.Default_Solution__c via field Solution_Category__c.CI_Default_Solution__c
	*/
	public static void Resolve_Solution_ForeginKeys(Solution_Category__c[] solCategory)
	{
		// Form a Set
		Set<String> defaultSolutionAkamIdSet = new Set<String>();
		for(Solution_Category__c solCat : solCategory)
			defaultSolutionAkamIdSet.add(solCat.CI_Default_Solution__c);
	
		// Query and Create a Map
		Map<String, Id> solCatIdMap = new Map<String, Id>();
		for(Solution__c sol : [select Id, AKAM_Solution_Id__c from Solution__c where AKAM_Solution_Id__c IN :defaultSolutionAkamIdSet])
			solCatIdMap.put(sol.AKAM_Solution_Id__c, sol.Id);
	
		// Make the Update
		for(Solution_Category__c solCat : solCategory)
		{
			solCat.Default_Solution__c = solCatIdMap.get(solCat.CI_Default_Solution__c);
			if(solCat.CI_Default_Solution__c != '' && solCat.Default_Solution__c == null)
				solCat.addError('Invalid Dafault Solution Id : ' + solCat.CI_Default_Solution__c);
		}
	}
	/**
	3. Resolve_PackageLine_ForeginKeys()
	- Resolved the Foreign Key relation of the field Package__c.PackageLines__c via field Package__c.CI_PackageLine__c
	*/
	public static void Resolve_PackageLine_ForeginKeys(Package__c[] packages)
	{
		// Form a Set
		Set<String> packageLineAkamIdSet = new Set<String>();
		for(Package__c pkg : packages)
			packageLineAkamIdSet.add(pkg.CI_PackageLine__c);
	
		// Query and Create a Map
		Map<String, Id> pkgLineIdMap = new Map<String, Id>();
		for(PackageLine__c pkgLines : [select Id, AKAM_PackageLine_Id__c from PackageLine__c where AKAM_PackageLine_Id__c IN :packageLineAkamIdSet])
			pkgLineIdMap.put(pkgLines.AKAM_PackageLine_Id__c, pkgLines.Id);
	
		// Make the Update
		for(Package__c pkg : packages)
		{
			pkg.PackageLines__c = pkgLineIdMap.get(pkg.CI_PackageLine__c);
			if(pkg.CI_PackageLine__c != '' && pkg.PackageLines__c == null)
				pkg.addError('Invalid PackageLine Id : ' + pkg.CI_PackageLine__c);
		}
	}
	
	/**
	4. Resolve_Package_ForeginKeys()
	- Resolved the Foreign Key relation of the field Package_Version__c.Package__c via field Package_Version__c.CI_Package__c
	*/
	public static void Resolve_Package_ForeginKeys(Package_Version__c[] pkgVersions)
	{
		// Form a Set
		Set<String> packageAkamIdSet = new Set<String>();
		for(Package_Version__c pkgVersion : pkgVersions)
			packageAkamIdSet.add(pkgVersion.CI_Package__c);
	
		// Query and Create a Map
		Map<String, Id> pkgIdMap = new Map<String, Id>();
		for(Package__c pkg : [select Id, AKAM_Package_Id__c from Package__c where AKAM_Package_Id__c IN :packageAkamIdSet])
			pkgIdMap.put(pkg.AKAM_Package_Id__c, pkg.Id);
	
		// Make the Update
		for(Package_Version__c pkgVersion : pkgVersions)
		{
			pkgVersion.Package__c = pkgIdMap.get(pkgVersion.CI_Package__c);
			if(pkgVersion.CI_Package__c != '' && pkgVersion.Package__c == null)
				pkgVersion.addError('Invalid Package Id : ' + pkgVersion.CI_Package__c);
		}
	}
	
	/**
	5. Resolve_Parent_Product_Category_ForeginKeys()
	- Resolved the Foreign Key relation of the field Product_Category__c.Parent_Product_Category__c via field Product_Category__c.CI_Parent_Product_Category__c
	*/
	public static void Resolve_Parent_Product_Category_ForeginKeys(Product_Category__c [] prodCategory)
	{
		// Form a Set
		Set<String> parentProdCategoryAkamIdSet = new Set<String>();
		for(Product_Category__c prdCategory : prodCategory)
			parentProdCategoryAkamIdSet.add(prdCategory.CI_Parent_Product_Category__c);
	
		// Query and Create a Map
		Map<String, Id> parentProdCategoryIdMap = new Map<String, Id>();
		for(Product_Category__c parentProductCat : [select Id, AKAM_Product_Category_Id__c from Product_Category__c where AKAM_Product_Category_Id__c IN :parentProdCategoryAkamIdSet])
			parentProdCategoryIdMap.put(parentProductCat.AKAM_Product_Category_Id__c, parentProductCat.Id);
	
		// Make the Update
		for(Product_Category__c prdCat : prodCategory)
		{
			prdCat.Parent_Product_Category__c = parentProdCategoryIdMap.get(prdCat.CI_Parent_Product_Category__c);
			if(prdCat.CI_Parent_Product_Category__c != '' && prdCat.Parent_Product_Category__c == null)
				prdCat.addError('Invalid ParentProductCategory Id : ' + prdCat.CI_Parent_Product_Category__c);
		}
	}
	/**
	6. Resolve_Product_Category_ForeginKeys()
	- Resolved the Foreign Key relation of the field Product__c.Product_Category__c via field Product__c.CI_Product_Category__c
	*/
	public static void Resolve_Product_Category_ForeginKeys(Product__c [] products)
	{
		// Form a Set
		Set<String> prodCategoryAkamIdSet = new Set<String>();
		for(Product__c prod : products)
			prodCategoryAkamIdSet.add(prod.CI_Product_Category__c);
	
		// Query and Create a Map
		Map<String, Id> prodCategoryIdMap = new Map<String, Id>();
		for(Product_Category__c prodCategory : [select Id, AKAM_Product_Category_Id__c from Product_Category__c where AKAM_Product_Category_Id__c IN :prodCategoryAkamIdSet])
			prodCategoryIdMap.put(prodCategory.AKAM_Product_Category_Id__c, prodCategory.Id);
	
		// Make the Update
		for(Product__c prod : products)
		{
			prod.Product_Category__c = prodCategoryIdMap.get(prod.CI_Product_Category__c);
			if(prod.CI_Product_Category__c != '' && prod.Product_Category__c == null)
				prod.addError('Invalid Product-Category Id : ' + prod.CI_Product_Category__c);
		}
	}
	/**
	7. Resolve_Solution_Territory_ForeginKeys()
	- Resolved the Foreign Key relation of the field 
	- Solution_Territory__c.Solution__c via field Solution_Territory__c.CI_Solution__c
	- Solution_Territory__c.Territory__c via field Solution_Territory__c.CI_Territory__c
	*/
	public static void Resolve_Solution_Territory_ForeginKeys(Solution_Territory__c [] solutionTerritory)
	{
		//Solution
		// Form a Set
		Set<String> solutionAkamIdSet = new Set<String>();
		for(Solution_Territory__c sol : solutionTerritory)
			solutionAkamIdSet.add(sol.CI_Solution__c);
	
		// Query and Create a Map
		Map<String, Id> solutionIdMap = new Map<String, Id>();
		for(Solution__c solution : [select Id, AKAM_Solution_Id__c from Solution__c where AKAM_Solution_Id__c IN :solutionAkamIdSet])
			solutionIdMap.put(solution.AKAM_Solution_Id__c, solution.Id);
	
		// Make the Update
		for(Solution_Territory__c solCat1 : solutionTerritory)
		{
			solCat1.Solution__c = solutionIdMap.get(solCat1.CI_Solution__c);
			if(solCat1.CI_Solution__c != '' && solCat1.Solution__c == null)
				solCat1.addError('Invalid Solution Id : ' + solCat1.CI_Solution__c);
		}
		
		//Territory
		// Form a Set
		Set<String> territoryAkamIdSet = new Set<String>();
		for(Solution_Territory__c ter : solutionTerritory)
			territoryAkamIdSet.add(ter.CI_Territory__c);
	
		// Query and Create a Map
		Map<String, Id> territoryIdMap = new Map<String, Id>();
		for(Territory__c territory : [select Id, AKAM_Territory_Id__c from Territory__c where AKAM_Territory_Id__c IN :territoryAkamIdSet])
			territoryIdMap.put(territory.AKAM_Territory_Id__c, territory.Id);
	
		// Make the Update
		for(Solution_Territory__c solCat2 : solutionTerritory)
		{
			solCat2.Territory__c = territoryIdMap.get(solCat2.CI_Territory__c);
			if(solCat2.CI_Territory__c != '' && solCat2.Territory__c == null)
				solCat2.addError('Invalid Territory Id : ' + solCat2.CI_Territory__c);
		}
	}
	
		/**
	8. Resolve_PackageVersion_Products_ForeginKeys()
	- Resolved the Foreign Key relation of the field 
	- PackageVersion_Products__c.Package_Version__c via field PackageVersion_Products__c.CI_Package_Version__c
	- PackageVersion_Products__c.Product__c via field PackageVersion_Products__c.CI_Product__c
	*/
	public static void Resolve_PackageVersion_Products_ForeginKeys(PackageVersion_Products__c [] pkgVersionProducts)
	{
		//PackageVersion
		// Form a Set
		Set<String> pkgVersionAkamIdSet = new Set<String>();
		for(PackageVersion_Products__c pvp : pkgVersionProducts)
			pkgVersionAkamIdSet.add(pvp.CI_Package_Version__c);
	
		// Query and Create a Map
		Map<String, Id> pkgVersionIdMap = new Map<String, Id>();
		for(Package_Version__c pkgVersion : [select Id, AKAM_Package_Version_Id__c from Package_Version__c where AKAM_Package_Version_Id__c IN :pkgVersionAkamIdSet])
			pkgVersionIdMap.put(pkgVersion.AKAM_Package_Version_Id__c, pkgVersion.Id);
	
		// Make the Update
		for(PackageVersion_Products__c pkgVersionProducts1 : pkgVersionProducts)
		{
			pkgVersionProducts1.Package_Version__c = pkgVersionIdMap.get(pkgVersionProducts1.CI_Package_Version__c);
			if(pkgVersionProducts1.CI_Package_Version__c != '' && pkgVersionProducts1.Package_Version__c == null)
				pkgVersionProducts1.addError('Invalid PackageVersion Id : ' + pkgVersionProducts1.CI_Package_Version__c);
		}
		
		//Product
		// Form a Set
		Set<String> productAkamIdSet = new Set<String>();
		for(PackageVersion_Products__c prod : pkgVersionProducts)
			productAkamIdSet.add(prod.CI_Product__c);
	
		// Query and Create a Map
		Map<String, Id> productIdMap = new Map<String, Id>();
		for(Product__c product : [select Id, AKAM_Product_Id__c from Product__c where AKAM_Product_Id__c IN :productAkamIdSet])
			productIdMap.put(product.AKAM_Product_Id__c, product.Id);
	
		// Make the Update
		for(PackageVersion_Products__c pkgVersionProducts2 : pkgVersionProducts)
		{
			pkgVersionProducts2.Product__c = productIdMap.get(pkgVersionProducts2.CI_Product__c);
			if(pkgVersionProducts2.CI_Product__c != '' && pkgVersionProducts2.Product__c == null)
				pkgVersionProducts2.addError('Invalid Product Id : ' + pkgVersionProducts2.CI_Product__c);
		}
	}
	
	/**
	9. Resolve_Solution_PackageVersion_ForeginKeys()
	- Resolved the Foreign Key relation of the field 
	- Solution_PackageVersion__c.Package_Version__c via field Solution_PackageVersion__c.CI_Package_Version__c
	- Solution_PackageVersion__c.Solution__c via field Solution_PackageVersion__c.CI_Solution__c
	*/
	public static void Resolve_Solution_PackageVersion_ForeginKeys(Solution_PackageVersion__c [] solPackageVersion)
	{
		//PackageVersion
		// Form a Set
		Set<String> pkgVersionAkamIdSet = new Set<String>();
		for(Solution_PackageVersion__c solPkgVersion : solPackageVersion)
			pkgVersionAkamIdSet.add(solPkgVersion.CI_Package_Version__c);
	
		// Query and Create a Map
		Map<String, Id> pkgVersionIdMap = new Map<String, Id>();
		for(Package_Version__c pkgVersion : [select Id, AKAM_Package_Version_Id__c from Package_Version__c where AKAM_Package_Version_Id__c IN :pkgVersionAkamIdSet])
			pkgVersionIdMap.put(pkgVersion.AKAM_Package_Version_Id__c, pkgVersion.Id);
	
		// Make the Update
		for(Solution_PackageVersion__c solPkgVersion1 : solPackageVersion)
		{
			solPkgVersion1.Package_Version__c = pkgVersionIdMap.get(solPkgVersion1.CI_Package_Version__c);
			if(solPkgVersion1.CI_Package_Version__c != '' && solPkgVersion1.Package_Version__c == null)
				solPkgVersion1.addError('Invalid PackageVersion Id : ' + solPkgVersion1.CI_Package_Version__c);
		}
		
		//Solution
		// Form a Set
		Set<String> solutionAkamIdSet = new Set<String>();
		for(Solution_PackageVersion__c solPkgVersion1 : solPackageVersion)
			solutionAkamIdSet.add(solPkgVersion1.CI_Solution__c);
	
		// Query and Create a Map
		Map<String, Id> solutionIdMap = new Map<String, Id>();
		for(Solution__c solution : [select Id, AKAM_Solution_Id__c from Solution__c where AKAM_Solution_Id__c IN :solutionAkamIdSet])
			solutionIdMap.put(solution.AKAM_Solution_Id__c, solution.Id);
	
		// Make the Update
		for(Solution_PackageVersion__c solPkgVersion2 : solPackageVersion)
		{
			solPkgVersion2.Solution__c = solutionIdMap.get(solPkgVersion2.CI_Solution__c);
			if(solPkgVersion2.CI_Solution__c != '' && solPkgVersion2.Solution__c == null)
				solPkgVersion2.addError('Invalid Solution Id : ' + solPkgVersion2.CI_Solution__c);
		}
	}
	
	/**
	10. Resolve_Solution_Purpose_ForeginKeys()
	- Resolved the Foreign Key relation of the field 
	- Solution_Purpose__c.Purpose__c via field Solution_Purpose__c.CI_Purpose__c
	- Solution_Purpose__c.Solution__c via field Solution_Purpose__c.CI_Solution__c
	*/
	public static void Resolve_Solution_Purpose_ForeginKeys(Solution_Purpose__c [] solutionPurpose)
	{
		//Purpose
		// Form a Set
		Set<String> purposeAkamIdSet = new Set<String>();
		for(Solution_Purpose__c solPurpose : solutionPurpose)
			purposeAkamIdSet.add(solPurpose.CI_Purpose__c);
	
		// Query and Create a Map
		Map<String, Id> purposeIdMap = new Map<String, Id>();
		for(Purpose__c purpose : [select Id, AKAM_Purpose_Id__c from Purpose__c where AKAM_Purpose_Id__c IN :purposeAkamIdSet])
			purposeIdMap.put(purpose.AKAM_Purpose_Id__c, purpose.Id);
	
		// Make the Update
		for(Solution_Purpose__c solPurpose1 : solutionPurpose)
		{
			solPurpose1.Purpose__c = purposeIdMap.get(solPurpose1.CI_Purpose__c);
			if(solPurpose1.CI_Purpose__c != '' && solPurpose1.Purpose__c == null)
				solPurpose1.addError('Invalid Purpose Id : ' + solPurpose1.CI_Purpose__c);
		}
		
		//Solution
		// Form a Set
		Set<String> solutionAkamIdSet = new Set<String>();
		for(Solution_Purpose__c solPurpose1 : solutionPurpose)
			solutionAkamIdSet.add(solPurpose1.CI_Solution__c);
	
		// Query and Create a Map
		Map<String, Id> solutionIdMap = new Map<String, Id>();
		for(Solution__c solution : [select Id, AKAM_Solution_Id__c from Solution__c where AKAM_Solution_Id__c IN :solutionAkamIdSet])
			solutionIdMap.put(solution.AKAM_Solution_Id__c, solution.Id);
	
		// Make the Update
		for(Solution_Purpose__c solPurpose2 : solutionPurpose)
		{
			solPurpose2.Solution__c = solutionIdMap.get(solPurpose2.CI_Solution__c);
			if(solPurpose2.CI_Solution__c != '' && solPurpose2.Solution__c == null)
				solPurpose2.addError('Invalid Solution Id : ' + solPurpose2.CI_Solution__c);
		}
	}
	
	/**
	11. Resolve_PackageVersion_Purpose_ForeginKeys()
	- Resolved the Foreign Key relation of the field 
	- PackageVersion_Purpose__c.Purpose__c via field PackageVersion_Purpose__c.CI_Purpose__c
	- PackageVersion_Purpose__c.Solution__c via field PackageVersion_Purpose__c.CI_Package_Version__c
	*/
	public static void Resolve_PackageVersion_Purpose_ForeginKeys(PackageVersion_Purpose__c [] pkgVersionPurpose)
	{
		//Purpose
		// Form a Set
		Set<String> purposeAkamIdSet = new Set<String>();
		for(PackageVersion_Purpose__c pkgVerPurpose : pkgVersionPurpose)
			purposeAkamIdSet.add(pkgVerPurpose.CI_Purpose__c);
	
		// Query and Create a Map
		Map<String, Id> purposeIdMap = new Map<String, Id>();
		for(Purpose__c purpose : [select Id, AKAM_Purpose_Id__c from Purpose__c where AKAM_Purpose_Id__c IN :purposeAkamIdSet])
			purposeIdMap.put(purpose.AKAM_Purpose_Id__c, purpose.Id);
	
		// Make the Update
		for(PackageVersion_Purpose__c pkgVerPurpose1 : pkgVersionPurpose)
		{
			pkgVerPurpose1.Purpose__c = purposeIdMap.get(pkgVerPurpose1.CI_Purpose__c);
			if(pkgVerPurpose1.CI_Purpose__c != '' && pkgVerPurpose1.Purpose__c == null)
				pkgVerPurpose1.addError('Invalid Purpose Id : ' + pkgVerPurpose1.CI_Purpose__c);
		}
		
		//PackageVersion
		// Form a Set
		Set<String> pkgVersionAkamIdSet = new Set<String>();
		for(PackageVersion_Purpose__c pkgVerPurpose1 : pkgVersionPurpose)
			pkgVersionAkamIdSet.add(pkgVerPurpose1.CI_Package_Version__c);
	
		// Query and Create a Map
		Map<String, Id> pkgVersionIdMap = new Map<String, Id>();
		for(Package_Version__c pkgVersion : [select Id, AKAM_Package_Version_Id__c from Package_Version__c where AKAM_Package_Version_Id__c IN :pkgVersionAkamIdSet])
			pkgVersionIdMap.put(pkgVersion.AKAM_Package_Version_Id__c, pkgVersion.Id);
	
		// Make the Update
		for(PackageVersion_Purpose__c pkgVerPurpose2 : pkgVersionPurpose)
		{
			pkgVerPurpose2.Package_Version__c = pkgVersionIdMap.get(pkgVerPurpose2.CI_Package_Version__c);
			if(pkgVerPurpose2.CI_Package_Version__c != '' && pkgVerPurpose2.Package_Version__c == null)
				pkgVerPurpose2.addError('Invalid PackageVersion Id : ' + pkgVerPurpose2.CI_Package_Version__c);
		}
	}
	
	
	
	
	
		/**
	11. Resolve_ProductLine_SolutionCategory_ForeginKeys()
	- Resolved the Foreign Key relation of the field 
	- ProductLine_SolutionCategory__c.Product_Line__c via field ProductLine_SolutionCategory__c.CI_Product_Line__c
	- ProductLine_SolutionCategory__c.Solution_Category__c via field ProductLine_SolutionCategory__c.CI_Solution_Category__c
	*/
	public static void Resolve_ProductLine_SolutionCategory_ForeginKeys(ProductLine_SolutionCategory__c [] prdLineSolnCategory)
	{
		//Purpose
		// Form a Set
		Set<String> productLineAkamIdSet = new Set<String>();
		Set<String> soluntionCategoryAkamIdSet = new Set<String>();
		
		for(ProductLine_SolutionCategory__c prodLineSolnCategory : prdLineSolnCategory){
			productLineAkamIdSet.add(prodLineSolnCategory.CI_Product_Line__c);
			soluntionCategoryAkamIdSet.add(prodLineSolnCategory.CI_Solution_Category__c);
		}
			
	
		// Query and Create a Map
		Map<String, Id> productLineIdMap = new Map<String, Id>();
		for(Product_Line__c productLine : [Select  Id, AKAM_Product_Line_Id__c From Product_Line__c where AKAM_Product_Line_Id__c IN :productLineAkamIdSet])
			productLineIdMap.put(productLine.AKAM_Product_Line_Id__c, productLine.Id);
	
		// Make the Update
		for(ProductLine_SolutionCategory__c prdLineSolnCat : prdLineSolnCategory)
		{
			prdLineSolnCat.Product_Line__c = productLineIdMap.get(prdLineSolnCat.CI_Product_Line__c);
			if(prdLineSolnCat.CI_Product_Line__c != '' && prdLineSolnCat.Product_Line__c == null)
				prdLineSolnCat.addError('Invalid Product Line Id : ' + prdLineSolnCat.CI_Product_Line__c);
		}
		


		// Query and Create a Map
		Map<String, Id> solnCategoryIdMap = new Map<String, Id>();
		for(Solution_Category__c solnCat : [Select Id, AKAM_Solution_Category_Id__c From Solution_Category__c  where AKAM_Solution_Category_Id__c IN :soluntionCategoryAkamIdSet])
			solnCategoryIdMap.put(solnCat.AKAM_Solution_Category_Id__c, solnCat.Id);
	
		// Make the Update
		for(ProductLine_SolutionCategory__c prdLineSolnCat : prdLineSolnCategory)
		{
			prdLineSolnCat.Solution_Category__c = solnCategoryIdMap.get(prdLineSolnCat.CI_Solution_Category__c);
			if(prdLineSolnCat.CI_Solution_Category__c != '' && prdLineSolnCat.Solution_Category__c == null)
				prdLineSolnCat.addError('Invalid Solution category Id : ' + prdLineSolnCat.CI_Solution_Category__c);
		}
		
	}
	
	
}