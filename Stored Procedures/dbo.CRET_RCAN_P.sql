SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[CRET_RCAN_P]
   @X XML
AS
BEGIN
   BEGIN TRY
      BEGIN TRAN CRET_RCAN_P_T1
         DECLARE @ErrorMessage NVARCHAR(MAX);
         DECLARE @Raid BIGINT
                ,@FromUser VARCHAR(250)
                ,@ToUser VARCHAR(250)
                ,@Amnt BIGINT
                ,@RcanStat VARCHAR(3)
                ,@AutoDoc VARCHAR(3)
                ,@ActnDate DATETIME
                ,@RcanRaid BIGINT;
         
         DECLARE C$RCAN CURSOR FOR
            SELECT x.query('.').value('(Receipt_Announcement/@raid)[1]'    , 'BIGINT')
                  ,x.query('.').value('(Receipt_Announcement/@fromuser)[1]'  , 'VARCHAR(250)')
                  ,x.query('.').value('(Receipt_Announcement/@touser)[1]'  , 'VARCHAR(250)')
                  ,x.query('.').value('(Receipt_Announcement/@amnt)[1]'    , 'BIGINT')
                  ,x.query('.').value('(Receipt_Announcement/@rcanstat)[1]', 'VARCHAR(3)')
                  ,x.query('.').value('(Receipt_Announcement/@autodoc)[1]' , 'VARCHAR(3)')
                  ,COALESCE(x.query('.').value('(Receipt_Announcement/@actndate)[1]', 'DATETIME'), GETDATE())
                  ,x.query('.').value('(Receipt_Announcement/@rcanraid)[1]', 'BIGINT')
              FROM @X.nodes('Receipt_Announcements/Receipt_Announcement') Ra(x);
         OPEN C$RCAN;
         FNFC$RCAN:
         FETCH NEXT FROM C$RCAN INTO @Raid, @FromUser, @ToUser, @Amnt, @RcanStat, @AutoDoc, @ActnDate, @RcanRaid;
         
         IF @@FETCH_STATUS <> 0
            GOTO CDC$RCAN;
         
         IF @Raid <> 0
         BEGIN
            IF @RcanStat = '003' -- تایید دریافت مبلغ
            BEGIN
               UPDATE Receipt_Announcement
                  SET RCAN_STAT = '003'
                WHERE RAID = @Raid;
               GOTO FNFC$RCAN;               
            END
            ELSE IF @RcanRaid = '004' -- عدم تایید دریافت مبلغ
            BEGIN
               UPDATE Receipt_Announcement
                  SET RCAN_STAT = '004'
                WHERE RAID = @Raid;               
               GOTO FNFC$RCAN;
            END
         END
         
         IF LEN(@ToUser) = 0 RAISERROR(N'فیلط "پرداخت به" مشخص نشده', 16, 1);
         IF (
            EXISTS(SELECT * FROM Receipt_Announcement WHERE RAID = @RcanRaid AND RCAN_STAT <> '003') OR
            EXISTS(SELECT * FROM Receipt_Announcement WHERE RCAN_RAID = @RcanRaid AND RCAN_STAT = '005')
         )
            RAISERROR(N'قبلا روی این سند عملیاتی انجام شده لطفا بررسی کنید', 16, 1);
         
         IF @Raid = 0 OR @Raid IS NULL
            EXEC dbo.INS_RCAN_P @Amnt, @FromUser, @ToUser, @RcanStat, @AutoDoc, @ActnDate, @RcanRaid, @Raid OUT;
         ELSE
            EXEC dbo.UPD_RCAN_P @Raid, @RcanStat, @ActnDate; 
         
         GOTO FNFC$RCAN;
         CDC$RCAN:
         CLOSE C$RCAN;
         DEALLOCATE C$RCAN;
      
      COMMIT TRAN CRET_RCAN_P_T1;
   END TRY
   BEGIN CATCH
  	   IF (SELECT CURSOR_STATUS('local','FNFC$RCAN')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','FNFC$RCAN')) > -1
         BEGIN
          CLOSE FNFC$RCAN
         END
       DEALLOCATE FNFC$RCAN
      END

      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN CRET_RCAN_P_T1   
   END CATCH;   
END;
GO
