/**
 * Utility class for temperature conversions.
 * Provides methods to convert between Celsius and Fahrenheit.
 */
public class TemperatureConverter {

    /**
     * Converts Celsius to Fahrenheit.
     * @param celsius The temperature in Celsius
     * @return The temperature in Fahrenheit
     */
    public static Decimal celsiusToFahrenheit(Decimal celsius) {
        if (celsius == null) {
            return null;
        }
        return (celsius * 9/5) + 32;
    }

    /**
     * Converts Fahrenheit to Celsius.
     * @param fahrenheit The temperature in Fahrenheit
     * @return The temperature in Celsius
     */
    public static Decimal fahrenheitToCelsius(Decimal fahrenheit) {
        if (fahrenheit == null) {
            return null;
        }
        return (fahrenheit - 32) * 5/9;
    }
}