/** 
 *  Description     :   This controller is used to assign Rule to products using Product Family.
 *
 *  Created Date    :   09/18/2015
 *
 *  Version         :   V_1.0
 *
 *  Revision Log    :   V_1.0- Created
**/
global with sharing class RuleToProductLineAssignmentController {
    
    //List of RevRecProductFamilySetting__c
    public List<RevRecProductFamilySetting__c> productFamilyRules {get;set;}
    public String ruleId {get; set;}
    public String oppLineItemRow {get;set;}
    
    //Set to hold the Family name
    Set<String> setFamilyNames = new Set<String>();
    
    //List of products to be updated
    List<Product2> productsToUpdate = new  List<Product2>();
    
    //Map is used to hold the field permission
    Static Map<String, Schema.DescribeFieldResult> mapfieldProduct2Result = Utility.getFieldPermissions('Product2');
    
    //Constructer
    public RuleToProductLineAssignmentController() {
    
        //Memory allocation 
        productFamilyRules = new List<RevRecProductFamilySetting__c>();
        
        //Query to fetch the records
        productFamilyRules = [Select Id, Name, RevRecRule__c, RevRecRule__r.Name From RevRecProductFamilySetting__c ORDER BY  Name ASC LIMIT 5000];
        
        //Loop over product families to get the family names in set
        for(RevRecProductFamilySetting__c prFam : productFamilyRules)
            setFamilyNames.add(prFam.Name) ;
    }
    
    /**
     *  @description    :   This method is used to assign the Revrec rule on products by their respective product family.
     *
     *  @args           :   
     *
     *  @return         :   Void
    **/
    public void doSave() {
        
        //Map to hold the family with rule
        Map<String , RevRecProductFamilySetting__c>  mapFamilyWithRule = new Map<String , RevRecProductFamilySetting__c>();
        
        //Loop over the list 
        for(RevRecProductFamilySetting__c productFamilySetting : productFamilyRules) 
            mapFamilyWithRule.put(productFamilySetting.Name , productFamilySetting);
        
        //Loop over products to fetch the reliable products
        for(Product2 prod : [Select Id, Family, RevRecRule__c, RevRecRule__r.Name From Product2 Where Family != '' AND Family != null AND 
                             Family IN : mapFamilyWithRule.keySet() AND IsActive = true AND
                             RevRecRule__c = null]) {
                                               
            //Assign revrecrule to products and add products into list to be update   
            if(Utility.checkFieldPermission(mapfieldProduct2Result,'RevRecRule__c',Constants.PERMISSION_UPSERT))                              
            	prod.RevRecRule__c = mapFamilyWithRule.get(prod.Family).RevRecRule__c;
            if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'Product2'))
            	productsToUpdate.add(prod);
        }
        
        //Checking for list size
        if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'Product2')){
            if(productsToUpdate.size() > 0)
                update productsToUpdate;
        }
        
        //Update Product families with rule
        update mapFamilyWithRule.values(); 
    }
    
    /**
     *  @description    :   This method is calling on page load action attribute.It is calling whenever the page get load.
     *
     *  @args           :   
     *
     *  @return         :   Void
    **/
    public void inIt() {
        
        //List of Product family setting to be inseted
        List<RevRecProductFamilySetting__c> pFamilyToBeInserted = new List<RevRecProductFamilySetting__c>();
        
        /** Getting the picklist values using describe method and populating wrapper**/
        Schema.DescribeFieldResult fieldResult = Product2.Family.getDescribe();     
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        //Loop over picklist entries and populate wrapper
        for( Schema.PicklistEntry f : ple) {
            
            if(!setFamilyNames.contains(f.getLabel()))
                pFamilyToBeInserted.add(new RevRecProductFamilySetting__c(Name = f.getLabel()));
        }  
       
        //Checking for the list size and insert the defaults
        if(pFamilyToBeInserted.size() > 0)
            performDML(JSON.serialize(pFamilyToBeInserted));
            //insert pFamilyToBeInserted ;
        
        //Query to fetch the records
        productFamilyRules = [Select Id, Name, RevRecRule__c, RevRecRule__r.Name From RevRecProductFamilySetting__c ORDER BY  Name ASC LIMIT 50000];
        
    }

    /**
     *  @description    :   This method is calling after page load action attribute.It is calling whenever the page get load.
     *
     *  @args           :   
     *
     *  @return         :   Void
    **/
    @future
    public static void performDML(String obj) {
        insert (List<RevRecProductFamilySetting__c>) JSON.deserialize(obj,RevRecProductFamilySetting__c.class);
    }
    
    //Used to fetch Contact for mobile user lookup using auto complete
    @RemoteAction
    global static List<RevRecRules__c> queryRules(String keywordDef3) {
        List<RevRecRules__c> rules = new List<RevRecRules__c>();
        if (keywordDef3 != null && keywordDef3.trim() != '') {
            keywordDef3 = '%' + keywordDef3 + '%';
            rules = [Select Id , Name , Recognition_Type__c from RevRecRules__c where Name like :keywordDef3];
        } else
            rules = [Select Id , Name , Recognition_Type__c from RevRecRules__c where Active__c = true];
        return rules;
    }  
    
    public void blankMethod() {
        
        //Checking for the row count
        if(String.isNotBlank(oppLineItemRow) && String.isNotBlank(ruleId)) 
            productFamilyRules[Integer.valueOf(oppLineItemRow)].RevRecRule__c = ruleId.trim();
    }
}