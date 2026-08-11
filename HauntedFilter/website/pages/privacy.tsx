import React from 'react';

export default function Privacy() {
  return (
    <div style={styles.container}>
      <header style={styles.header}>
        <nav style={styles.nav}>
          <a href="/" style={styles.navLink}>← 返回首页</a>
        </nav>
        <h1 style={styles.title}>隐私政策</h1>
        <p style={styles.date}>最后更新日期: 2024年8月11日</p>
      </header>

      <main style={styles.main}>
        <section style={styles.section}>
          <p style={styles.intro}>
            本隐私政策说明了 werck it!- video degrader（压烂它！）如何收集、使用和保护您的信息。我们承诺保护您的隐私。
          </p>
        </section>

        <section style={styles.section}>
          <h2 style={styles.sectionTitle}>1. 信息收集</h2>
          <p style={styles.text}>
            werck it!- video degrader（压烂它！）尊重您的隐私。所有视频处理都在您的设备本地完成，我们不会将您的视频上传到任何服务器。
          </p>
        </section>

        <section style={styles.section}>
          <h2 style={styles.sectionTitle}>2. 数据使用</h2>
          <p style={styles.text}>
            我们收集的信息仅用于改进应用功能和用户体验。我们不会与第三方分享您的个人信息。
          </p>
        </section>

        <section style={styles.section}>
          <h2 style={styles.sectionTitle}>3. 数据安全</h2>
          <p style={styles.text}>
            您的视频文件始终存储在您的设备本地。我们采取合理的技术措施保护您的信息。
          </p>
        </section>

        <section style={styles.section}>
          <h2 style={styles.sectionTitle}>4. 联系我们</h2>
          <p style={styles.text}>
            如果您对本隐私政策有任何疑问，请通过以下方式联系我们：
          </p>
          <div style={styles.contact}>
            <p><strong>邮箱：</strong> privacy@werckit-app.com</p>
            <p><strong>技术支持：</strong> <a href="/support" style={styles.link}>werckit-app.com/support</a></p>
          </div>
        </section>

        <section style={styles.note}>
          <p>
            <strong>重要提示：</strong>使用 werck it!- video degrader（压烂它！）应用即表示您同意本隐私政策。
            我们可能会不时更新本政策，更新后的政策将在本页面发布。
          </p>
        </section>
      </main>

      <footer style={styles.footer}>
        <div style={styles.footerLinks}>
          <a href="/" style={styles.footerLink}>首页</a>
          <a href="/support" style={styles.footerLink}>技术支持</a>
          <a href="/terms" style={styles.footerLink}>使用条款</a>
        </div>
        <p>© 2024 werck it!- video degrader（压烂它！）. All rights reserved.</p>
      </footer>
    </div>
  );
}

const styles = {
  container: {
    minHeight: '100vh',
    backgroundColor: '#000',
    color: '#fff',
    fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
    padding: '20px',
    maxWidth: '800px',
    margin: '0 auto',
    lineHeight: '1.6',
  },
  header: {
    marginBottom: '40px',
    borderBottom: '1px solid #333',
    paddingBottom: '20px',
  },
  nav: {
    marginBottom: '20px',
  },
  navLink: {
    color: '#888',
    textDecoration: 'none' as const,
    fontSize: '16px',
  },
  title: {
    fontSize: '36px',
    fontWeight: 'bold' as const,
    marginBottom: '10px',
    color: '#fff',
  },
  date: {
    color: '#666',
    fontSize: '14px',
  },
  main: {
    marginBottom: '40px',
  },
  section: {
    marginBottom: '30px',
    padding: '20px',
    backgroundColor: '#111',
    borderRadius: '8px',
  },
  intro: {
    fontSize: '18px',
    color: '#aaa',
    marginBottom: '20px',
  },
  sectionTitle: {
    fontSize: '24px',
    fontWeight: '600' as const,
    marginBottom: '15px',
    color: '#fff',
    borderBottom: '2px solid #333',
    paddingBottom: '10px',
  },
  text: {
    fontSize: '16px',
    color: '#aaa',
    marginBottom: '15px',
  },
  contact: {
    backgroundColor: '#1a1a1a',
    padding: '20px',
    borderRadius: '8px',
    marginTop: '20px',
  },
  link: {
    color: '#4dabf7',
    textDecoration: 'none' as const,
  },
  note: {
    backgroundColor: '#1a1a1a',
    padding: '25px',
    borderRadius: '8px',
    borderLeft: '4px solid #4dabf7',
    marginTop: '30px',
  },
  footer: {
    textAlign: 'center' as const,
    paddingTop: '20px',
    borderTop: '1px solid #333',
    color: '#666',
  },
  footerLinks: {
    display: 'flex',
    justifyContent: 'center',
    gap: '20px',
    marginBottom: '20px',
    flexWrap: 'wrap' as const,
  },
  footerLink: {
    color: '#888',
    textDecoration: 'none' as const,
    fontSize: '16px',
  },
};