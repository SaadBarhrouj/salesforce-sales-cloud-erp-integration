/**
 * @description Service layer for Bundle_Option__c business logic.
 * Handles bundle data retrieval, option payload construction, validation, and CRUD operations.
 * Builds dynamic bundle configuration data for LWC consumption.
 * @author Sales Cloud ERP Integration Team
 */
public inherited sharing class BundleOptionService {

    private static final String OTHER_FEATURE_ID = 'feature_other';
    private static final String OTHER_FEATURE_NAME = 'Other';

    private static final List<String> TRACKED_FIELDS = new List<String>{
        'Id',
        'Name',
        'Bundle_Product__c',
        'Default_Quantity__c',
        'Feature__c',
        'Is_Required__c',
        'Is_Selected__c',
        'Max_Quantity__c',
        'Min_Quantity__c',
        'Option_Product__c',
        'Option_Type__c',
        'Quantity_Editable__c',
        'Sort_Order__c'
    };

    /**
     * @description Retrieves complete bundle configuration data including features and options.
     * Organizes options by feature and creates special "Other" feature for unassigned options.
     * Prepares data structure optimized for LWC consumption.
     * Bundle name is retrieved via LDS getRecord in LWC for better performance and caching.
     * @param bundleId The ID of the bundle product (Product2)
     * @return Map containing features list with structured option data
     * @throws BundleOptionException If bundleId is null or bundle product not found
     */
    public static Map<String, Object> getBundleData(Id bundleId) {
        if (bundleId == null) {
            throw new BundleOptionException('Bundle ID is required.');
        }

        Product2 bundleProduct = Product2DAO.getById(bundleId);
        if (bundleProduct == null) {
            throw new BundleOptionException('Bundle not found for the provided ID.');
        }

        List<Bundle_Feature__c> featureRecords = BundleFeatureDAO.getByProductId(bundleId);
        List<Bundle_Option__c> optionRecords = BundleOptionDAO.getByBundleProductId(bundleId);

        List<Map<String, Object>> featurePayloads = new List<Map<String, Object>>();
        Map<Id, Map<String, Object>> featurePayloadById = new Map<Id, Map<String, Object>>();

        for (Bundle_Feature__c featureRecord : featureRecords) {
            Map<String, Object> featurePayload = new Map<String, Object>{
                'Id' => String.valueOf(featureRecord.Id),
                'Name' => featureRecord.Name,
                'helpText' => featureRecord.Help_Text__c,
                'minOptions' => featureRecord.Min_Options__c,
                'maxOptions' => featureRecord.Max_Options__c,
                'options' => new List<Map<String, Object>>()
            };
            featurePayloads.add(featurePayload);
            featurePayloadById.put(featureRecord.Id, featurePayload);
        }

        List<Map<String, Object>> otherOptions = new List<Map<String, Object>>();

        for (Bundle_Option__c optionRecord : optionRecords) {
            Map<String, Object> optionPayload = buildOptionPayload(optionRecord);

            if (optionRecord.Feature__c != null && featurePayloadById.containsKey(optionRecord.Feature__c)) {
                List<Map<String, Object>> featureOptions = (List<Map<String, Object>>) featurePayloadById.get(optionRecord.Feature__c).get('options');
                featureOptions.add(optionPayload);
            } else {
                otherOptions.add(optionPayload);
            }
        }

        if (!otherOptions.isEmpty()) {
            featurePayloads.add(new Map<String, Object>{
                'Id' => OTHER_FEATURE_ID,
                'Name' => OTHER_FEATURE_NAME,
                'helpText' => System.Label.Bundle_Other_Feature_Description,
                'minOptions' => null,
                'maxOptions' => null,
                'options' => otherOptions
            });
        }

        return new Map<String, Object>{
            'features' => featurePayloads
        };
    }

    /**
     * @description Constructs a normalized option payload map for LWC consumption.
     * Uses only the data already loaded in the optionRecord (including relationships).
     * Handles null values with sensible defaults.
     * @param optionRecord The Bundle_Option__c record to transform
     * @return Map with keys: Id, Name, productCode, productName, description,
     *         defaultQuantity, minQuantity, maxQuantity, quantityEditable, isRequired, isSelected, optionType
     */
    private static Map<String, Object> buildOptionPayload(Bundle_Option__c optionRecord) {
        Product2 product = optionRecord.Option_Product__r;
        String optionProductId = optionRecord.Option_Product__c == null
            ? null
            : String.valueOf(optionRecord.Option_Product__c);
        
        return new Map<String, Object>{
            'Id' => String.valueOf(optionRecord.Id),
            'Name' => optionRecord.Name,
            'productId' => optionProductId,
            'productCode' => product?.ProductCode ?? '',
            'productName' => product?.Name ?? '',
            'description' => product?.Description ?? '',
            'defaultQuantity' => optionRecord.Default_Quantity__c ?? 0,
            'minQuantity' => optionRecord.Min_Quantity__c,
            'maxQuantity' => optionRecord.Max_Quantity__c,
            'quantityEditable' => optionRecord.Quantity_Editable__c ?? false,
            'isRequired' => optionRecord.Is_Required__c ?? false,
            'isSelected' => optionRecord.Is_Selected__c ?? false,
            'optionType' => optionRecord.Option_Type__c
        };
    }

    /**
     * @description Compares a current record against its persisted version to detect field-level changes.
     * Only tracked fields are compared. Uses string value comparison to handle different data types.
     * @param currentRecord The current state of the Bundle_Option__c record
     * @param persistedRecord The previously saved state of the Bundle_Option__c record
     * @return True if any tracked field has changed, false otherwise
     */
    @TestVisible
    private static Boolean hasChanges(Bundle_Option__c currentRecord, Bundle_Option__c persistedRecord) {
        for (String fieldApiName : TRACKED_FIELDS) {
            if (valuesDiffer(currentRecord.get(fieldApiName), persistedRecord.get(fieldApiName))) {
                return true;
            }
        }
        return false;
    }

    /**
     * @description Compares two values by converting them to strings.
     * Handles null values and type mismatches safely.
     * @param leftValue The first value to compare
     * @param rightValue The second value to compare
     * @return True if the string representations differ, false if they are the same
     */
    @TestVisible
    private static Boolean valuesDiffer(Object leftValue, Object rightValue) {
        return String.valueOf(leftValue) != String.valueOf(rightValue);
    }
}