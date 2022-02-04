/*
 *  oxPush2 is available under the MIT License (2008). See http://opensource.org/licenses/MIT for full text.
 *
 *  Copyright (c) 2014, Gluu
 */

package org.gluu.super_gluu.app.model;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Helper class for providing sample content for user interfaces created by
 * Android template wizards.
 *
 * TODO: Replace all uses of this class before publishing your app.
 */
public class KeyContent {

    /**
     * An array of sample (key) items.
     */
    public static final List<KeyItem> ITEMS = new ArrayList<KeyItem>();

    /**
     * A map of sample (key) items, by ID.
     */
    public static final Map<String, KeyItem> ITEM_MAP = new HashMap<String, KeyItem>();

    private static final int COUNT = 25;

    static {
        // Add some sample items.
        for (int i = 1; i <= COUNT; i++) {
            addItem(createKeyItem(i));
        }
    }

    private static void addItem(KeyItem item) {
        ITEMS.add(item);
        ITEM_MAP.put(item.id, item);
    }

    private static KeyItem createKeyItem(int position) {
        return new KeyItem(String.valueOf(position), "Item " + position, makeDetails(position));
    }

    private static String makeDetails(int position) {
        StringBuilder builder = new StringBuilder();
        builder.append("Details about Item: ").append(position);
        for (int i = 0; i < position; i++) {
            builder.append("\nMore details information here.");
        }
        return builder.toString();
    }

    /**
     * A key item representing a piece of content.
     */
    public static class KeyItem {
        public final String id;
        public final String content;
        public final String details;

        public KeyItem(String id, String content, String details) {
            this.id = id;
            this.content = content;
            this.details = details;
        }

        @Override
        public String toString() {
            return content;
        }
    }
}
