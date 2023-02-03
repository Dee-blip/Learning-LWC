public class PLM_SalesTeamReportControllerTestClass {

	
	private static ProductLine_SolutionCategory__c CreateProductLineSolutionCategory(Id pl, Id sc){
		
		ProductLine_SolutionCategory__c plsc = new ProductLine_SolutionCategory__c();
		plsc.Name = 'test name';
		plsc.Product_Line__c = pl;
		plsc.Solution_Category__c = sc;
		
		return plsc;
		
	}		
	
	private static Solution_Category__c CreateSolutionCategory(String name){
		
		Solution_Category__c sc = new Solution_Category__c();
		sc.Name = name;
		
		return sc;
	}	
	
	private static Product_Line__c CreateProductLine(String name){
		
		Product_Line__c pl = new Product_Line__c();
		pl.Name = name;
		
		return pl;
	}	
	
	
	private static Solution__c CreateSolution(Id solnCat, String name, String akamId){
		
		Solution__c soln = new Solution__c();
		soln.Solution_Category__c = solnCat;
		soln.Name = name;
		soln.AKAM_Solution_Id__c = akamId;
		soln.Solution_Expiration_Date__c = null;
		return soln;
		
	}
	
	
	
	private static Solution_PackageVersion__c CreateSolutionPackageVersion(Id soln, Id pv,String akamId){
		
		Solution_PackageVersion__c spv = new Solution_PackageVersion__c();
		spv.Solution__c = soln;
		spv.Package_Version__c = pv;
		spv.AKAM_Solution_PackageVersion_Id__c = akamId;
		return spv;
	}
	
	
	private static Package_Version__c  CreatePackageVersion(Id pkgId, String name){
		
		Package_Version__c pv = new Package_Version__c();
		pv.Name = name;
		pv.Package__c = pkgId;
		pv.Approval_Status_Code__c = '410';
		return pv; 
		
	}
	
	private static Package__c CreatePackage(String name, Id pkgLineId, String variant){
		
		Package__c pkg = new Package__c();
		pkg.Name = name;
		pkg.PackageLines__c = pkgLineId;
		pkg.Variant__c = variant;
		return pkg;
		
	}
	
	
	private static PackageLine__c CreatePackageLine(String name){
		
		PackageLine__c pl = new PackageLine__c();
		pl.Name = name;
		pl.PackageLine_Name__c = name;
		return pl;
		
	} 
	
	
	private static PackageVersion_Products__c CreatePackageVersionProduct(String name, Id pkgver, Id prodId,String akamId){
		
		PackageVersion_Products__c pvp = new PackageVersion_Products__c();
		pvp.Product__c = prodId;
		pvp.Package_Version__c = pkgver;
		pvp.AKAM_PackageVersion_Products_Id__c = akamId;
		
		return pvp;
		
	}
	
	
	private static Product__c CreateProduct(String name, Id prdCat){
		
		Product__c prd = new Product__c();
		prd.Name = name;
		prd.Product_Category__c = prdCat;
		
		return prd;
	}
	
	private static Product_Category__c CreateProductCategory(String name, Id prdLine){
		
		Product_Category__c prdCat = new Product_Category__c();
		prdCat.Name = name;		
		prdCat.Product_Line__c = prdLine;
		
		return prdCat;
		
	} 
	
	/**
		test methods go here
	*/
	 testMethod static void testGetSolutionCategory(){
		
		Solution_Category__c sc = CreateSolutionCategory('SolnCat');
		insert sc;

		Product_Line__c pl = CreateProductLine('ProdLine');
		insert pl;
		
		
		ProductLine_SolutionCategory__c plsc = CreateProductLineSolutionCategory(pl.Id, sc.Id);
		insert plsc;
		
		Test.startTest();
		PLM_SalesTeamReportController strc = new PLM_SalesTeamReportController();
		
		String[] pLine = new List<String>();
		pLine.add(pl.Id);

		strc.setSelectedProductLine(pLine);
		List<SelectOption> plscList = strc.getSolutionCategoryPickList();
		System.assertEquals(plscList.get(0).getValue(), sc.Id);
		
		Test.stopTest();
	} 
	
	testMethod static void testGetProductLine(){
		
		Product_Line__c pl = CreateProductLine('ProdLine');
		insert pl;
		
		Test.startTest();
		PLM_SalesTeamReportController strc = new PLM_SalesTeamReportController();
		
		List<SelectOption> plList = strc.getProductLineList();
		System.debug('size'+ plList.size());

		for(SelectOption so: plList){
			
			if(so.getLabel().equals('ProdLine')){
			System.assertEquals(so.getValue(),pl.Id);
			}

			
		}
		
		Test.stopTest();
		
		
		
		
	}
	
	testMethod static void testGetPackageLinePickList(){
		
		
		PackageLine__c pl = CreatePackageLine('packageline1');
		insert pl;
		
		Package__c pkg = CreatePackage('Package',pl.Id, 'MPV');
		insert pkg;
		
		Package_Version__c pkgver = CreatePackageVersion(pkg.Id, 'packageVersion');
		insert pkgver;
		
		Solution_Category__c sc = CreateSolutionCategory('SolnCat');
		insert sc;
		
		Solution__c soln = CreateSolution(sc.Id, 'Soln','PC-SO-0001');
		insert soln;
		
		Solution_PackageVersion__c solnpkgver = CreateSolutionPackageVersion(soln.Id, pkgver.Id, 'PC-AKAM-0001');
		insert solnpkgver;
		
		
		Test.startTest();
		PLM_SalesTeamReportController strc = new PLM_SalesTeamReportController();
			
		String[] selectedSolnCat = new List<String>();
		selectedSolnCat.add(sc.Id);
		
		strc.setSelectedSolutionCategory(selectedSolnCat);
		
		List<SelectOption> plList = strc.getPackageLinePickList();
		System.assertEquals(plList.get(0).getValue(), pl.Id);
		
		Test.stopTest();
		
		
	}
	
	
	testMethod static void testGenerateReport(){
		
		
		PackageLine__c pl = CreatePackageLine('packageline1');
		insert pl;
		
		Package__c pkg = CreatePackage('Package',pl.Id, 'MPV');
		insert pkg;
		
		Package_Version__c pkgver = CreatePackageVersion(pkg.Id, 'packageVersion');
		insert pkgver;
		
		Solution_Category__c sc = CreateSolutionCategory('SolnCat');
		insert sc;
		
		Solution__c soln = CreateSolution(sc.Id, 'Soln','PC-SO-0001');
		insert soln;
		
		Solution_PackageVersion__c solnpkgver = CreateSolutionPackageVersion(soln.Id, pkgver.Id, 'PC-AKAM-0001');
		insert solnpkgver;
		
		Product_Line__c prdl = CreateProductLine('ProdLine');
		insert prdl;
		
		Product_Category__c prdCat = CreateProductCategory('Prodcat', prdl.Id );
		insert prdCat;
		
		Product__c prd = CreateProduct('Product', prdCat.Id);
		insert prd;
		
		PackageVersion_Products__c pvp = CreatePackageVersionProduct('PkgVerProd', pkgver.Id, prd.Id, 'PC-AAK-001' );
		insert pvp;
		
		Test.startTest();
		PLM_SalesTeamReportController strc = new PLM_SalesTeamReportController();
			
		String[] selectedPkgLine = new List<String>();
		selectedPkgLine.add(pl.Id);
		
		strc.setSelectedPkgLine(selectedPkgLine);
		
		strc.generateReport();
		
		System.assertEquals(strc.getPdwList().get(0).getProductList().get(0).Id, prd.Id);
		System.assertEquals(strc.getPdwList().get(0).getPackageVerionName(), 'MPV');
		System.assertEquals(strc.getPdwList().get(0).getPackageLineName(),'packageline1');

		
		Test.stopTest();
		
		
	}
	
	
	testMethod static void testPageInvocation(){


		Solution_Category__c sc = CreateSolutionCategory('SolnCat');
		insert sc;

		Product_Line__c pl = CreateProductLine('ProdLine');
		insert pl;
		
		
		ProductLine_SolutionCategory__c plsc = CreateProductLineSolutionCategory(pl.Id, sc.Id);
		insert plsc;
		

		PackageLine__c pkgl = CreatePackageLine('packageline1');
		insert pkgl;
		
		Package__c pkg = CreatePackage('Package',pkgl.Id, 'MPV');
		insert pkg;
		
		Package_Version__c pkgver = CreatePackageVersion(pkg.Id, 'packageVersion');
		insert pkgver;

		Solution__c soln = CreateSolution(sc.Id, 'Soln','PC-SO-0001');
		insert soln;
		
		Solution_PackageVersion__c solnpkgver = CreateSolutionPackageVersion(soln.Id, pkgver.Id, 'PC-AKAM-0001');
		insert solnpkgver;		
		
		Test.startTest();
		PLM_SalesTeamReportController strc = new PLM_SalesTeamReportController();
		
		String[] pLine = new List<String>();
		pLine.add(pl.Id);
		strc.setSelectedProductLine(pLine);

		String[] selectedSolnCat = new List<String>();
		selectedSolnCat.add(sc.Id);
		strc.setSelectedSolutionCategory(selectedSolnCat);


		List<SelectOption> scList = strc.getSolutionCategoryPickList();
		List<SelectOption> plList = strc.getProductLineList();
		List<SelectOption> pkglList = strc.getPackageLinePickList();
		
		System.assert(strc.getSelectedProductLine().size() > 0);
		System.assert(strc.getSelectedSolutionCategory().size() > 0);
		
		
		Test.stopTest();
		
		
		
		
	}
	
	
	
	
	
	
	


}