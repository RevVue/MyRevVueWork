global class RevRecRuleWrapper {
    
    @AuraEnabled 
    public RevRecRules__c rule {get; set; }
    
    @AuraEnabled 
    public String Revenue_Recognition_End_Date_display {get; set;} 
    
    @AuraEnabled 
    public String Revenue_Recognition_Start_Date_display {get; set;}
    
    @AuraEnabled 
    public  List<String> categoryValueTypes {get;set;} 
    
    //Blended Revenue Revenue Recognition Start Date
    @AuraEnabled 
    public List<String> revenueRecogStartDates {get;set;}
    
    //Blended Revenue Revenue Recognition End Date 
    @AuraEnabled 
    public List<String> revenueRecogEndDates {get;set;}
    
}