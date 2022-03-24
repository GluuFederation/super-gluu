package org.gluu.super_gluu.store.dao;

import androidx.lifecycle.LiveData;
import androidx.room.Dao;
import androidx.room.Delete;
import androidx.room.Insert;
import androidx.room.Query;
import androidx.room.Update;

import org.gluu.super_gluu.store.entity.LogInfoEntry;
import org.gluu.super_gluu.store.entity.UserTokenEntry;

import java.util.List;

@Dao
public interface LogInfoEntryDAO {

    @Query("SELECT * FROM logInfoEntry ORDER BY createdDate DESC")
    LiveData<List<LogInfoEntry>> getAll();

    @Query("SELECT * FROM logInfoEntry WHERE id = :id")
    LogInfoEntry getById(int id);

    @Insert
    void insert(LogInfoEntry logInfoEntry);

    @Update
    void update(LogInfoEntry logInfoEntry);

    @Delete
    void delete(UserTokenEntry tokenEntry);

    @Query("DELETE FROM logInfoEntry where id in (:idList)")
    void delete(List<Integer> idList);

    @Query("DELETE FROM logInfoEntry")
    void deleteAll();
}
