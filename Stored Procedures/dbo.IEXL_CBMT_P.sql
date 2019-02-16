SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[IEXL_CBMT_P] 
   @X XML
AS
BEGIN
   BEGIN TRY 
   BEGIN TRAN T_EXCL_CBMT_P
   DECLARE @ClubCode BIGINT
          ,@CochFileNo BIGINT
          ,@MtodCode BIGINT
          ,@StrtTime TIME(0)
          ,@EndTime TIME(0)
          ,@pridTime INT
          ,@SatDay VARCHAR(3)
          ,@SunDay VARCHAR(3)
          ,@MonDay VARCHAR(3)
          ,@TusDay VARCHAR(3)
          ,@WnsDay VARCHAR(3)
          ,@TrsDay VARCHAR(3)
          ,@FriDay VARCHAR(3);
   
   SELECT @ClubCode   = @X.query('Club_Method').value('(Club_Method/@clubcode)[1]', 'BIGINT')
         ,@CochFileNo = @X.query('Club_Method').value('(Club_Method/@cochfileno)[1]', 'BIGINT')
         ,@MtodCode   = @X.query('Club_Method').value('(Club_Method/@mtodcode)[1]', 'BIGINT')
         ,@StrtTime   = @X.query('Club_Method').value('(Club_Method/@strttime)[1]', 'TIME(0)')
         ,@EndTime    = @X.query('Club_Method').value('(Club_Method/@endtime)[1]', 'TIME(0)')
         ,@PridTime   = @X.query('Club_Method').value('(Club_Method/@pridtime)[1]', 'INT')
         ,@SatDay     = @X.query('Club_Method').value('(Club_Method/@satday)[1]', 'VARCHAR(3)')
         ,@SunDay     = @X.query('Club_Method').value('(Club_Method/@sunday)[1]', 'VARCHAR(3)')
         ,@MonDay     = @X.query('Club_Method').value('(Club_Method/@monday)[1]', 'VARCHAR(3)')
         ,@TusDay     = @X.query('Club_Method').value('(Club_Method/@tusday)[1]', 'VARCHAR(3)')
         ,@WnsDay     = @X.query('Club_Method').value('(Club_Method/@wnsday)[1]', 'VARCHAR(3)')
         ,@TrsDay     = @X.query('Club_Method').value('(Club_Method/@trsday)[1]', 'VARCHAR(3)')
         ,@FriDay     = @X.query('Club_Method').value('(Club_Method/@friday)[1]', 'VARCHAR(3)');
   
   -- Temp Variable
   DECLARE @iTime TIME(0) = @StrtTime
          ,@jTime TIME(0) = DATEADD(MINUTE, @pridTime, @StrtTime)
          ,@CbmtCode BIGINT;
   
   WHILE @iTime <= @EndTime
   BEGIN      
      IF NOT EXISTS
      (
         SELECT *
           FROM dbo.Club_Method cm--, dbo.Club_Method_Weekday cmw
          WHERE cm.CLUB_CODE = @ClubCode
            AND cm.COCH_FILE_NO = @CochFileNo
            AND cm.MTOD_CODE = @MtodCode
            AND cm.STRT_TIME = @iTime
            AND cm.END_TIME = @jTime
            AND EXISTS(
                SELECT *
                  FROM dbo.Club_Method_Weekday cmw
                 WHERE cm.CODE = cmw.CBMT_CODE
                   AND cmw.STAT = '002'
                   AND cmw.STAT = CASE cmw.WEEK_DAY
                                       WHEN '007' THEN @SatDay
                                       WHEN '001' THEN @SunDay
                                       WHEN '002' THEN @MonDay
                                       WHEN '003' THEN @TusDay
                                       WHEN '004' THEN @WnsDay
                                       WHEN '005' THEN @TrsDay
                                       WHEN '006' THEN @FriDay
                                  END
            )
      )
      BEGIN
         EXEC dbo.INS_CBMT_P 
             @Club_Code = @ClubCode, -- bigint
             @Mtod_Code = @MtodCode, -- bigint
             @Coch_File_No = @CochFileNo, -- bigint
             @Day_Type = '003', -- varchar(3)
             @Strt_Time = @iTime, -- time
             @End_Time = @jTime, -- time
             @Sex_Type = '003', -- varchar(3)
             @Cbmt_Desc = N'excl_cbmt_p', -- nvarchar(250)
             @Dflt_Stat = '001', -- varchar(3)
             @Cpct_Numb = 0, -- int
             @Cpct_Stat = '001', -- varchar(3)
             @Cbmt_Time = 0, -- int
             @Cbmt_Time_Stat = '001', -- varchar(3)
             @Clas_Time = 0, -- int
             @Amnt = 0; -- bigint
         
         SELECT @CbmtCode = CODE
           FROM dbo.Club_Method
          WHERE CBMT_DESC = 'excl_cbmt_p'
            AND CRET_BY = UPPER(SUSER_NAME());      
      END
      ELSE
         SELECT @CbmtCode = cm.CODE
           FROM dbo.Club_Method cm--, dbo.Club_Method_Weekday cmw
          WHERE cm.CLUB_CODE = @ClubCode
            AND cm.COCH_FILE_NO = @CochFileNo
            AND cm.MTOD_CODE = @MtodCode
            AND cm.STRT_TIME = @iTime
            AND cm.END_TIME = @jTime;
            
      UPDATE dbo.Club_Method_Weekday
         SET STAT = CASE WEEK_DAY 
                         WHEN '007' THEN @SatDay
                         WHEN '001' THEN @SunDay
                         WHEN '002' THEN @MonDay
                         WHEN '003' THEN @TusDay
                         WHEN '004' THEN @WnsDay
                         WHEN '005' THEN @TrsDay
                         WHEN '006' THEN @FriDay
                    END
       WHERE CBMT_CODE = @CbmtCode;
      
      UPDATE dbo.Club_Method
         SET CBMT_DESC = NULL
       WHERE CODE = @CbmtCode;
       
      SET @iTime = DATEADD(MINUTE, @pridTime, @iTime);
      SET @jTime = DATEADD(MINUTE, @pridTime, @iTime);
   END;
   
   COMMIT TRAN T_EXCL_CBMT_P;
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(250)
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T_EXCL_CBMT_P;
   END CATCH;
END
GO
