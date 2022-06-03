package org.gluu.super_gluu.store.Converter;

import androidx.room.TypeConverter;

import java.util.Date;

public class DateTimeConverter {

    /**
     * Convert Date to an string
     */
    @TypeConverter
    public static long fromDateToLong(Date value) {
        return value.getTime();
    }

    /**
     * Convert an string to LogState
     */
    @TypeConverter
    public static Date fromLongToDate(long value) {
        return new Date(value);
    }
}
