package org.gluu.super_gluu.store.Converter;

import androidx.room.TypeConverter;

import org.gluu.super_gluu.app.LogState;

public class LogStateConverter {

    /**
     * Convert LogState to an string
     */
    @TypeConverter
    public static String fromLogStateToString(LogState value) {
        return value.toString();
    }

    /**
     * Convert an string to LogState
     */
    @TypeConverter
    public static LogState fromStringToLogState(String value) {
        return LogState.valueOf(value);
    }
}
