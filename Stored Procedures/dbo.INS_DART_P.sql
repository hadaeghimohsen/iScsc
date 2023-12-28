SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[INS_DART_P]
   @AttnCode BIGINT,
   @ComaCode BIGINT,
   @EdevCode BIGINT = DEFAULT
AS
BEGIN   
   BEGIN TRY
   BEGIN TRAN INS_DART_P_T      
      -- اختصاص کلید کمد به کاربر اگر سامانه کمد فعال باشد و به صورت اتوماتیک انجام شود
      IF EXISTS(SELECT * FROM Attendance A WHERE A.CODE = @AttnCode AND A.EXIT_TIME IS NULL)
         --OR EXISTS(SELECT * FROM Attendance A, Fighter F WHERE A.CODE = @AttnCode AND A.FIGH_FILE_NO = F.FILE_NO AND F.FGPB_TYPE_DNRM = '008' AND CONF_STAT = '002')
      BEGIN
         DECLARE @DresCode BIGINT,
                 @DresNumb INT,
                 @FileNo BIGINT,
                 @MbspRwno SMALLINT;
                --,@ClubCode BIGINT;
         --SELECT @ClubCode = Club_Code FROM Attendance WHERE CODE = @AttnCode;
         
         --IF EXISTS(SELECT * FROM Dresser_Attendance WHERE ATTN_CODE = @AttnCode)
         --BEGIN
         --   RAISERROR(N'قبلا برای این هنرجو کمد رزور شده است' , 16, 1);
         --END
         
         UPDATE dbo.Dresser_Attendance
            SET TKBK_TIME = CAST(GETDATE() AS TIME(0))
          WHERE CAST(CRET_DATE AS DATE) <= CAST(DATEADD(DAY, -1, GETDATE()) AS DATE);
         
         -- آیا قبلا برای این حضور و غیاب کمدی اختصاص داده شده است یا خیر
         SELECT TOP 1 
                @DresCode = DRES_CODE,
                @FileNo = FIGH_FILE_NO
           FROM Dresser_Attendance 
          WHERE ATTN_CODE = @AttnCode;
         
         -- اگر سیستم کامپیوتری مشخص نباشد
         IF @ComaCode IS NULL
            SELECT @ComaCode = COMA_CODE
              FROM dbo.Dresser
             WHERE CODE = @DresCode;
         
         -- کمدی به این حضوری اختصاص داده نشده است
         IF @DresCode IS NULL
         BEGIN
            SELECT @FileNo = a.FIGH_FILE_NO,
                   @MbspRwno = a.MBSP_RWNO_DNRM
              FROM dbo.Attendance a
             WHERE a.CODE = @AttnCode;
             
            SELECT TOP 1 
                   @DresCode = CODE,
                   @DresNumb = D.DRES_NUMB
              FROM Dresser D 
             WHERE D.Rec_Stat = '002'       
               AND D.COMA_CODE = @ComaCode
               AND (@EdevCode IS NULL 
                    OR EXISTS (
                       SELECT * 
                         FROM dbo.External_Device ed 
                        WHERE ed.CODE = @EdevCode 
                          AND ed.IP_ADRS = d.IP_ADRS 
                       )
                   )
               -- اگر مشتری کمد VIP ثبت شده باشد
               AND (EXISTS (
                    SELECT * 
                      FROM dbo.Dresser_Vip_Fighter dv 
                     WHERE dv.MBSP_FIGH_FILE_NO = @FileNo 
                       --AND dv.MBSP_RWNO = @MbspRwno
                       AND dv.STAT = '002' 
                       AND dv.DRES_CODE = d.CODE
                       AND d.VIP_STAT = '002'
                    )
                    OR ISNULL(d.VIP_STAT, '001') = '001'
                       AND NOT EXISTS (
                           SELECT *
                             FROM dbo.Dresser_Vip_Fighter dv
                            WHERE dv.MBSP_FIGH_FILE_NO = @FileNo
                              AND dv.STAT = '002'
                              AND dv.DRES_CODE != d.CODE
                       ) )
               AND NOT EXISTS(
                  SELECT * 
                    FROM Dresser_Attendance Da
                   WHERE Da.DRES_CODE = D.CODE
                     AND Da.Lend_Time IS NOT NULL
                     AND Da.Tkbk_Time IS NULL
               )
             ORDER BY D.ORDR;
            
            
         END
         
         IF @DresCode IS NOT NULL
            INSERT INTO Dresser_Attendance (Dres_Code, Attn_Code, FIGH_FILE_NO, Code, Lend_Time, DERS_NUMB)
            VALUES (@DresCode, @AttnCode, @FileNo, dbo.Gnrt_Nvid_U(), CAST(GETDATE() AS TIME(0)), @DresNumb);
         --ELSE
         --BEGIN         
         --   RAISERROR(N'متاسفانه کمد خالی در سالن وجود ندارد', 16, 1);
         --END
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
