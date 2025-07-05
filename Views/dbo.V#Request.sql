SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[V#Request]
AS
SELECT     r.REGN_PRVN_CNTY_CODE, r.REGN_PRVN_CODE, r.REGN_CODE, r.RQST_RQID, r.RQID, r.RQTP_CODE, r.RQTT_CODE, r.SUB_SYS, r.RQST_STAT, r.RQST_DATE, r.SAVE_DATE, r.LETT_NO, 
                      r.LETT_DATE, r.LETT_OWNR, r.SSTT_MSTT_SUB_SYS, r.SSTT_MSTT_CODE, r.SSTT_CODE, r.YEAR, r.CYCL, r.SEND_EXPN, r.MDUL_NAME, r.SECT_NAME, r.RQST_NUMB, r.RQST_DESC, 
                      r.REF_SUB_SYS, r.REF_CODE, r.AMNT_TYPE_DNRM, r.CRET_BY, r.CRET_DATE, r.MDFY_BY, r.MDFY_DATE, rr.FIGH_FILE_NO, p.PYMT_NO, p.PYMT_PYMT_NO, p.SUM_EXPN_PRIC, 
                      p.SUM_EXPN_EXTR_PRCT, p.SUM_REMN_PRIC, p.SUM_RCPT_EXPN_PRIC, p.SUM_RCPT_EXPN_EXTR_PRCT, p.SUM_RCPT_REMN_PRIC, p.SUM_PYMT_DSCN_DNRM, p.CASH_BY, 
                      p.CASH_DATE, p.AMNT_UNIT_TYPE_DNRM, p.PROF_AMNT_DNRM, p.DEDU_AMNT_DNRM, dbo.D$ATYP.DOMN_DESC AS AMNT_TYPE_DESC, r.INVC_DATE, r.INVC_NUMB
FROM         dbo.D$ATYP INNER JOIN
                      dbo.Payment AS p ON dbo.D$ATYP.VALU = p.AMNT_UNIT_TYPE_DNRM RIGHT OUTER JOIN
                      dbo.Request AS r INNER JOIN
                      dbo.Request_Row AS rr ON r.RQID = rr.RQST_RQID ON r.RQTP_CODE = '009' AND r.RQTT_CODE = '004' AND r.RQST_RQID = p.RQST_RQID OR r.RQID = p.RQST_RQID
WHERE     (r.RQST_STAT = '002')
GO
EXEC sp_addextendedproperty N'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[48] 4[14] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "D$ATYP"
            Begin Extent = 
               Top = 32
               Left = 561
               Bottom = 122
               Right = 721
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "p"
            Begin Extent = 
               Top = 47
               Left = 910
               Bottom = 167
               Right = 1122
            End
            DisplayFlags = 280
            TopColumn = 30
         End
         Begin Table = "r"
            Begin Extent = 
               Top = 98
               Left = 249
               Bottom = 218
               Right = 463
            End
            DisplayFlags = 280
            TopColumn = 29
         End
         Begin Table = "rr"
            Begin Extent = 
               Top = 181
               Left = 512
               Bottom = 301
               Right = 726
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 48
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Widt', 'SCHEMA', N'dbo', 'VIEW', N'V#Request', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_DiagramPane2', N'h = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', 'SCHEMA', N'dbo', 'VIEW', N'V#Request', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=2
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'V#Request', NULL, NULL
GO
