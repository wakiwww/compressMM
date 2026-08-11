import React from 'react';

export default function Home() {
  return (
    <div style={styles.container}>
      <header style={styles.header}>
        <h1 style={styles.title}>werck it!- video degrader（压烂它！）</h1>
        <p style={styles.subtitle}>将视频压烂成阴间风格</p>
      </header>

      <main style={styles.main}>
        <section style={styles.section}>
          <h2 style={styles.sectionTitle}>欢迎访问 werck it!- video degrader（压烂它！）官方网站</h2>
          <p style={styles.text}>
            werck it!- video degrader（压烂它！）是一款创新的视频处理工具，通过先进的算法将您的视频压烂成阴间风格。
          </p>
        </section>

        <section style={styles.section}>
          <h2 style={styles.sectionTitle}>重要链接</h2>
          <div style={styles.links}>
            <a href="/support" style={styles.link}>技术支持</a>
            <a href="/privacy" style={styles.link}>隐私政策</a>
            <a href="/terms" style={styles.link}>使用条款</a>
          </div>
        </section>

        <section style={styles.section}>
          <h2 style={styles.sectionTitle}>App Store 提交信息</h2>
          <div style={styles.info}>
            <p><strong>应用名称：</strong>werck it!- video degrader（压烂它！）</p>
            <p><strong>技术支持网址：</strong>https://werckit-app.com/support</p>
            <p><strong>营销网址：</strong>https://werckit-app.com</p>
            <p><strong>隐私政策：</strong>https://werckit-app.com/privacy</p>
          </div>
        </section>
      </main>

      <footer style={styles.footer}>
        <p>© 2024 werck it!- video degrader（压烂它！）. All rights reserved.</p>
        <p style={styles.footerNote}>此为 App Store 提交所需的官方网站</p>
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
    maxWidth: '1200px',
    margin: '0 auto',
  },
  header: {
    textAlign: 'center' as const,
    marginBottom: '50px',
    paddingBottom: '20px',
    borderBottom: '1px solid #333',
  },
  title: {
    fontSize: '48px',
    fontWeight: 'bold' as const,
    marginBottom: '10px',
    color: '#fff',
  },
  subtitle: {
    fontSize: '20px',
    color: '#888',
  },
  main: {
    lineHeight: '1.6',
  },
  section: {
    marginBottom: '40px',
    padding: '20px',
    backgroundColor: '#111',
    borderRadius: '8px',
  },
  sectionTitle: {
    fontSize: '24px',
    fontWeight: '600' as const,
    marginBottom: '20px',
    color: '#fff',
  },
  text: {
    fontSize: '16px',
    color: '#aaa',
    marginBottom: '15px',
  },
  links: {
    display: 'flex',
    gap: '20px',
    flexWrap: 'wrap' as const,
  },
  link: {
    color: '#4dabf7',
    textDecoration: 'none' as const,
    fontSize: '18px',
    padding: '10px 20px',
    backgroundColor: '#222',
    borderRadius: '4px',
    transition: 'background-color 0.3s',
  },
  info: {
    backgroundColor: '#1a1a1a',
    padding: '20px',
    borderRadius: '8px',
  },
  footer: {
    textAlign: 'center' as const,
    marginTop: '50px',
    paddingTop: '20px',
    borderTop: '1px solid #333',
    color: '#666',
  },
  footerNote: {
    fontSize: '14px',
    marginTop: '10px',
    color: '#888',
  },
};