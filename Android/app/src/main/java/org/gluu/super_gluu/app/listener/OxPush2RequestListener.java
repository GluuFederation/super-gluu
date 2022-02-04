/*
 *  oxPush2 is available under the MIT License (2008). See http://opensource.org/licenses/MIT for full text.
 *
 *  Copyright (c) 2014, Gluu
 */

package org.gluu.super_gluu.app.listener;


import org.gluu.super_gluu.model.OxPush2Request;
import org.gluu.super_gluu.model.U2fMetaData;
import org.gluu.super_gluu.u2f.v2.exception.U2FException;
import org.gluu.super_gluu.u2f.v2.model.TokenResponse;
import org.gluu.super_gluu.u2f.v2.store.DataStore;
import org.json.JSONException;

import java.io.IOException;

/**
 * OxPush2 listener
 *
 * Created by Yuriy Movchan on 01/07/2016.
 */
public interface OxPush2RequestListener {

    void onQrRequest(OxPush2Request oxPush2Request);

    TokenResponse onSign(String jsonRequest, U2fMetaData u2fMetaData, Boolean isDeny) throws JSONException, IOException, U2FException;

    TokenResponse onEnroll(String jsonRequest, OxPush2Request oxPush2Request, Boolean isDeny) throws JSONException, IOException, U2FException;

    DataStore onGetDataStore();
}
