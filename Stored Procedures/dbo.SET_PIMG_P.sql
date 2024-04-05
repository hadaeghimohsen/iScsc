SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[SET_PIMG_P]
   @X XML
AS
BEGIN
   DECLARE @FileNo BIGINT
          ,@RcdcRcid BIGINT
          ,@Rwno SMALLINT;
   SELECT @FileNo = @X.query('Fighter').value('(Fighter/@fileno)[1]', 'BIGINT')
         ,@RcdcRcid = @X.query('Fighter/Image').value('(Image/@rcdcrcid)[1]', 'BIGINT')
         ,@Rwno = @X.query('Fighter/Image').value('(Image/@rwno)[1]', 'SMALLINT');
   
   UPDATE Fighter
      SET IMAG_RCDC_RCID_DNRM = @RcdcRcid
         ,IMAG_RWNO_DNRM = @Rwno
    WHERE FILE_NO = @FileNo;
   
   -- 1402/12/02 * Update All Record Attendance is null image profile id
   UPDATE dbo.Attendance
      SET IMAG_RCDC_RCID_DNRM = @RcdcRcid
         ,IMAG_RWNO_DNRM = @Rwno
    WHERE FIGH_FILE_NO = @FileNo
      AND IMAG_RCDC_RCID_DNRM IS NULL;
END;
GO
