global class ProductRuleCategoryWrapper {

	//Variables 
    @AuraEnabled 
    public RevRecProductRuleCategory__c revRecProductCategory {get ; set;}
    
    @AuraEnabled 
    public integer rowCount{get;set;}
    
    @AuraEnabled  
    public List<String> lineItemForBlended1 {get;set;}
    
    @AuraEnabled 
    public boolean isSelected {get;set;}
    
    //Constructer
    public ProductRuleCategoryWrapper(RevRecProductRuleCategory__c revRecProductCategory, integer rowCount, List<String> lineItemForBlended1, Boolean isSelected) {
                                         
        //Initilization
        this.revRecProductCategory = revRecProductCategory;  
        this.rowCount = rowCount;   
        this.lineItemForBlended1 = lineItemForBlended1;   
        this.isSelected = isSelected;
    }
}