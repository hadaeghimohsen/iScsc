SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SET_ADNA_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
BEGIN TRY	
   BEGIN TRAN T$SET_ADNA_P
   
   -- Local Params
   DECLARE @AttnCode BIGINT,
           @FileNo BIGINT,
           @ClubCode BIGINT,
           @MbspRwno SMALLINT;
   SELECT @AttnCode = @X.query('//Attendance').value('(Attendance/@code)[1]', 'BIGINT')
         ,@FileNo = @X.query('//Attendance').value('(Attendance/@fileno)[1]', 'BIGINT')
         ,@ClubCode  = @X.query('//Attendance').value('(Attendance/@clubcode)[1]', 'BIGINT')
         ,@MbspRwno = @X.query('//Attendance').value('(Attendance/@mbsprwno)[1]', 'SMALLINT');
   
   -- Local Vars
   DECLARE @HostName NVARCHAR(128) = dbo.GET_HOST_U()
          ,@ComaCode BIGINT;
   
   -- 1398/03/14 * اختصاص شماره کمد به مشتری
   -- البته اگر این گزینه کمد انلاین فعال باشه 
   -- 1396/01/09 * بدست آوردن کلاینت متصل به سرور
   IF EXISTS(SELECT * FROM dbo.Settings WHERE CLUB_CODE = @ClubCode AND DRES_AUTO = '002') 
      AND NOT EXISTS (
          SELECT *
            FROM dbo.Exception_Operation
           WHERE FIGH_FILE_NO = @FileNo
             AND EXCP_TYPE = '003' -- OnLine Lock Cabinet
             AND STAT = '002'
      )
   BEGIN
      -- ابتدا بررسی میکنیم که چه کامیپوتری به کمد ها میخواد فرمان دهد
      --SELECT   
      --    @HostName = s.host_name
      --  FROM sys.dm_exec_connections AS c  
      --  JOIN sys.dm_exec_sessions AS s  
      --    ON c.session_id = s.session_id  
      -- WHERE c.session_id = @@SPID; 
      
      SELECT TOP 1 
             @ComaCode = ca.CODE
        FROM dbo.Computer_Action ca
       WHERE EXISTS (
             SELECT *
               FROM dbo.Dresser d
              WHERE d.COMA_CODE = ca.CODE
         );
      
      -- بررسی میکنیم که ایا سیستم مدیریت کمدی رو را انجام میدهد یا خیر
      IF EXISTS(SELECT * FROM dbo.Dresser WHERE COMA_CODE = @ComaCode AND REC_STAT = '002')
      BEGIN
         DECLARE @MtodCode BIGINT = NULL, 
                 @EdevCode BIGINT = NULL;
         --SELECT @AttnCode = MAX(CODE)                   
         --  FROM Attendance
         -- WHERE FIGH_FILE_NO = @FileNo
         --   AND CLUB_CODE = @ClubCode
         --   AND MBSP_RWNO_DNRM = @MbspRwno
         --   AND ENTR_TIME IS NOT NULL
         --   AND EXIT_TIME IS NULL;
         
         SELECT @MtodCode = MTOD_CODE_DNRM
           FROM dbo.Attendance
          WHERE CODE = @AttnCode;            
          
         -- 1402/10/03 * اگر رشته ها بر اساس دستگاه های سنترال تفکیک شده باشند
         IF (
            NOT EXISTS (SELECT * FROM dbo.External_Device_Link_Method WHERE STAT = '002') OR
            EXISTS (SELECT * FROM dbo.External_Device_Link_Method m WHERE m.STAT = '002' AND m.MTOD_CODE = @MtodCode)
         )
         BEGIN
            SELECT @EdevCode = EDEV_CODE
              FROM dbo.External_Device_Link_Method
             WHERE MTOD_CODE = @MtodCode
               AND STAT = '002';
            
            -- 1403/08/20 * IF EdevCode IS NOT NULL WE MUST CHECK Computer Code
            IF @EdevCode IS NOT NULL
            BEGIN
               -- We find the best record for admin
               SELECT TOP 1
                      @ComaCode = d.COMA_CODE
                 FROM dbo.External_Device ed, dbo.Dresser d
                WHERE ed.CODE = @EdevCode
                  AND ed.IP_ADRS = d.IP_ADRS;
            END 
            
            -- 1403/12/09 * اگر قبلا کمدی برای ایت حضور و غیاب ثبت شده آن را غیر فعال کنید
            DELETE dbo.Dresser_Attendance 
               --SET TKBK_TIME = GETDATE()
             WHERE ATTN_CODE = @AttnCode;
               --AND TKBK_TIME IS NULL;
            UPDATE dbo.Attendance SET DERS_NUMB = NULL, NUMB_OPEN_DNRM = 0 WHERE CODE = @AttnCode;
            
            -- اولین درخواست ثبت قفل کمدی
            EXEC dbo.INS_DART_P @AttnCode, @ComaCode, @EdevCode;
            
            -- اگر درخواست قفل کمدی با موفقیت انجام شود
            IF EXISTS(SELECT * FROM dbo.Dresser_Attendance WHERE ATTN_CODE = @AttnCode)
            BEGIN                  
               -- ثبت شماره قفل کمدی
               UPDATE dbo.Attendance 
                  SET DERS_NUMB = (SELECT d.DRES_NUMB FROM dbo.Dresser_Attendance da, dbo.Dresser d WHERE da.ATTN_CODE = @AttnCode AND da.DRES_CODE = d.CODE AND da.DRAT_CODE IS NULL AND da.TKBK_TIME IS NULL)
                WHERE Code = @AttnCode;
            END
         END 
      END                
   END

   COMMIT TRAN [T$SET_ADNA_P]
END TRY
BEGIN CATCH
   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
   RAISERROR ( @ErorMesg, -- Message text.
            16, -- Severity.
            1 -- State.
            );
   ROLLBACK TRAN [T$SET_ADNA_P]
END CATCH
END
GO
