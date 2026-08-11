import React from 'react';
import Head from 'next/head';

export default function HomePage() {
  return (
    <div style={styles.container}>
      <Head>
        <title>Rêverie - 引领画质新潮流</title>
        <meta name="description" content="Rêverie 是一款创新视频处理工具，通过先进的算法为您的视频添加独特的艺术效果。" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main style={styles.main}>
        <div style={styles.hero}>
          <h1 style={styles.title}>Rêverie</h1>
          <p style={styles.subtitle}>引领画质新潮流</p>

          <div style={styles.description}>
            <p>Rêverie 是一款创新视频处理工具，通过先进的算法为您的视频添加独特的艺术效果。</p>
            <p>体验前所未有的视频降质艺术，将普通视频转化为独特的视觉体验。</p>
          </div>

          <div style={styles.features}>
            <div style={styles.featureCard}>
              <h3 style={styles.featureTitle}>🎨 艺术效果</h3>
              <p>多种独特的视频效果选择</p>
            </div>
            <div style={styles.featureCard}>
              <h3 style={styles.featureTitle}>⚡ 实时处理</h3>
              <p>快速处理，立即查看效果</p>
            </div>
            <div style={styles.featureCard}>
              <h3 style={styles.featureTitle}>🔧 精细控制</h3>
              <p>自定义调整效果强度</p>
            </div>
          </div>

          <div style={styles.downloadSection}>
            <p style={styles.downloadText}>立即在 App Store 下载 Rêverie</p>
            <div style={styles.appStoreBadge}>
              <span style={styles.badgeText}>Available on the</span>
              <span style={styles.badgeTitle}>App Store</span>
            </div>
          </div>
        </div>

        <div style={styles.links}>
          <a href="/support" style={styles.link}>技术支持</a>
          <a href="/privacy" style={styles.link}>隐私政策</a>
          <a href="/terms" style={styles.link}>使用条款</a>
          <a href="mailto:support@reverie-app.com" style={styles.link}>联系我们</a>
        </div>
      </main>

      <footer style={styles.footer}>
        <p>© 2024 Rêverie. All rights reserved.</p>
      </footer>
    </div>
  );
}

const styles = {
  container: {
    minHeight: '100vh',
    backgroundColor: '#000',
    color: '#fff',
    fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
  },
  main: {
    maxWidth: '1200px',
    margin: '0 auto',
    padding: '40px 20px',
  },
  hero: {
    textAlign: 'center' as const,
    marginBottom: '60px',
  },
  title: {
    fontSize: '48px',
    fontWeight: 'bold' as const,
    marginBottom: '10px',
    color: '#fff',
  },
  subtitle: {
    fontSize: '24px',
    color: '#888',
    marginBottom: '40px',
  },
  description: {
    fontSize: '18px',
    lineHeight: '1.6',
    color: '#aaa',
    maxWidth: '800px',
    margin: '0 auto 50px',
  },
  features: {
    display: 'flex',
    justifyContent: 'center',
    gap: '30px',
    flexWrap: 'wrap' as const,
    marginBottom: '50px',
  },
  featureCard: {
    backgroundColor: '#111',
    padding: '30px',
    borderRadius: '12px',
    width: '250px',
    textAlign: 'center' as const,
  },
  featureTitle: {
    fontSize: '20px',
    marginBottom: '15px',
    color: '#fff',
  },
  downloadSection: {
    marginTop: '40px',
  },
  downloadText: {
    fontSize: '20px',
    marginBottom: '20px',
    color: '#888',
  },
  appStoreBadge: {
    display: 'inline-block',
    backgroundColor: '#000',
    border: '2px solid #888',
    borderRadius: '8px',
    padding: '12px 24px',
    cursor: 'pointer',
  },
  badgeText: {
    display: 'block',
    fontSize: '12px',
    color: '#888',
  },
  badgeTitle: {
    display: 'block',
    fontSize: '24px',
    fontWeight: 'bold' as const,
    color: '#fff',
  },
  links: {
    display: 'flex',
    justifyContent: 'center',
    gap: '30px',
    flexWrap: 'wrap' as const,
    marginTop: '40px',
    paddingTop: '40px',
    borderTop: '1px solid #222',
  },
  link: {
    color: '#888',
    textDecoration: 'none' as const,
    fontSize: '16px',
    transition: 'color 0.3s',
  },
  footer: {
    textAlign: 'center' as const,
    padding: '40px 20px',
    color: '#666',
    fontSize: '14px',
    borderTop: '1px solid #222',
    marginTop: '60px',
  },
};