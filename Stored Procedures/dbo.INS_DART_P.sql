SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[INS_DART_P]
   @AttnCode BIGINT
AS
BEGIN   
   BEGIN TRY
   BEGIN TRAN INS_DART_P_T
      -- اختصاص کلید کمد به کاربر اگر سامانه کمد فعال باشد و به صورت اتوماتیک انجام شود
      IF EXISTS(SELECT * FROM Attendance A WHERE A.CODE = @AttnCode AND A.EXIT_TIME IS NULL)
         OR EXISTS(SELECT * FROM Attendance A, Fighter F WHERE A.CODE = @AttnCode AND A.FIGH_FILE_NO = F.FILE_NO AND F.FGPB_TYPE_DNRM = '008' AND CONF_STAT = '002')
      BEGIN
         DECLARE @DresCode BIGINT
                ,@ClubCode BIGINT;
         SELECT @ClubCode = Club_Code FROM Attendance WHERE CODE = @AttnCode;
         
         IF EXISTS(SELECT * FROM Dresser_Attendance WHERE ATTN_CODE = @AttnCode)
         BEGIN
            RAISERROR(N'قبلا برای این هنرجو کمد رزور شده است' , 16, 1);
         END
         
         SELECT TOP 1 
                @DresCode = CODE
           FROM Dresser D 
          WHERE D.Rec_Stat = '002'       
            AND CLUB_CODE = @ClubCode
            AND NOT EXISTS(
               SELECT * 
                 FROM Dresser_Attendance Da
                WHERE Da.DRES_CODE = D.CODE
                  AND Da.Lend_Time IS NOT NULL
                  AND Da.Tkbk_Time IS NULL
            );
         IF @DresCode IS NOT NULL
            INSERT INTO Dresser_Attendance (Dres_Code, Attn_Code, Code, Lend_Time)
            VALUES (@DresCode, @AttnCode, dbo.Gnrt_Nvid_U(), CAST(GETDATE() AS TIME(0)));
      END
      COMMIT TRAN INS_DART_P_T
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN INS_DART_P_T;
   END CATCH
END;
GO
