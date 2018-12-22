SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[INS_MBSM_P]
   @Mbsp_Figh_File_No BIGINT,
   @Mbsp_Rwno SMALLINT,
   @Mbsp_Rect_Code VARCHAR(3),
   @Mark_Code BIGINT,
   @Mark_Numb FLOAT,
   @Mark_Desc NVARCHAR(500)
AS 
BEGIN
   IF NOT EXISTS(
      SELECT * 
        FROM dbo.Member_Ship_Mark
       WHERE MBSP_FIGH_FILE_NO = @Mbsp_Figh_File_No
         AND MBSP_RECT_CODE = @Mbsp_Rect_Code
         AND MBSP_RWNO = @Mbsp_Rwno
         AND MARK_CODE = @Mark_Code
   )
   BEGIN
      INSERT INTO dbo.Member_Ship_Mark
              ( MBSP_FIGH_FILE_NO ,
                MBSP_RWNO ,
                MBSP_RECT_CODE ,
                MARK_CODE ,
                CODE ,
                MARK_NUMB ,
                MARK_DESC 
              )
      VALUES  ( @Mbsp_Figh_File_No , -- MBSP_FIGH_FILE_NO - bigint
                @Mbsp_Rwno , -- MBSP_RWNO - smallint
                @Mbsp_Rect_Code , -- MBSP_RECT_CODE - varchar(3)
                @Mark_Code , -- MARK_CODE - bigint
                0 , -- CODE - bigint
                @Mark_Numb , -- MARK_NUMB - float
                @Mark_Desc 
              );
   END;
   
END;
GO
