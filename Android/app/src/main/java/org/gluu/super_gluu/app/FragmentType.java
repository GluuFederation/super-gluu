package org.gluu.super_gluu.app;

/**
 * Created by nazaryavornytskyy on 3/31/16.
 */
public class FragmentType {

    public enum FRAGMENT_TYPE {
        MAIN_FRAGMENT, LOGS_FRAGMENT, KEYS_FRAGMENT, SETTINGS_FRAGMENT
    }

    public enum SETTINGS_FRAGMENT_TYPE {
        PIN_CODE_FRAGMENT(0),
        FINGERPRINT_FRAGMENT(1),
        SSL_FRAGMENT(2),
        USER_GUIDE_FRAGMENT(3),
        PRIVACY_POLICY_FRAGMENT(4),
        AD_FREE_FRAGMENT(5),
        VERSION_FRAGMENT(6),
        EMPTY_FRAGMENT(7);

        private final int value;

        SETTINGS_FRAGMENT_TYPE(int i) {
            value = i;
        }
    }
}
