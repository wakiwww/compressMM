#!/usr/bin/env python3
"""
GeoJSON 验证工具 - 确保文件符合 App Store Connect 要求
"""

import json
import sys
import os

def validate_geojson(file_path):
    """验证 GeoJSON 文件是否符合 App Store Connect 要求"""
    try:
        with open(file_path, 'r') as f:
            data = json.load(f)

        print(f"验证文件: {os.path.basename(file_path)}")
        print("-" * 50)

        # 1. 基础验证
        if 'type' not in data:
            print("❌ 错误: 缺少 'type' 字段")
            return False
        print(f"✅ 类型: {data['type']}")

        # 2. 检查是否是有效的几何类型
        valid_types = ['FeatureCollection', 'MultiPolygon']
        if data['type'] not in valid_types:
            print(f"❌ 错误: 类型必须是 {valid_types} 之一")
            return False

        # 3. 根据类型进行详细验证
        if data['type'] == 'FeatureCollection':
            return validate_feature_collection(data)
        elif data['type'] == 'MultiPolygon':
            return validate_multipolygon(data)

    except json.JSONDecodeError as e:
        print(f"❌ JSON 解析错误: {e}")
        return False
    except Exception as e:
        print(f"❌ 未知错误: {e}")
        return False

    return True

def validate_feature_collection(data):
    """验证 FeatureCollection 类型"""
    if 'features' not in data:
        print("❌ 错误: FeatureCollection 缺少 'features' 字段")
        return False

    features = data['features']
    if not isinstance(features, list):
        print("❌ 错误: 'features' 必须是数组")
        return False

    if len(features) != 1:
        print("❌ 错误: 只能包含一个 Feature 元素")
        return False

    feature = features[0]
    if feature.get('type') != 'Feature':
        print("❌ 错误: Feature 类型不正确")
        return False

    if 'geometry' not in feature:
        print("❌ 错误: Feature 缺少 'geometry' 字段")
        return False

    geometry = feature['geometry']
    if geometry.get('type') != 'MultiPolygon':
        print("❌ 错误: 几何类型必须是 'MultiPolygon'")
        return False

    return validate_multipolygon_coordinates(geometry.get('coordinates', []))

def validate_multipolygon(data):
    """验证 MultiPolygon 类型"""
    if 'coordinates' not in data:
        print("❌ 错误: MultiPolygon 缺少 'coordinates' 字段")
        return False

    return validate_multipolygon_coordinates(data['coordinates'])

def validate_multipolygon_coordinates(coordinates):
    """验证 MultiPolygon 坐标"""
    if not isinstance(coordinates, list):
        print("❌ 错误: 'coordinates' 必须是数组")
        return False

    print(f"✅ 包含 {len(coordinates)} 个多边形")

    # 验证每个多边形
    for i, polygon in enumerate(coordinates):
        if not isinstance(polygon, list):
            print(f"❌ 错误: 多边形 {i} 必须是数组")
            return False

        for j, ring in enumerate(polygon):
            if not isinstance(ring, list):
                print(f"❌ 错误: 多边形 {i} 环 {j} 必须是数组")
                return False

            # 检查环是否闭合（首尾坐标相同）
            if len(ring) < 4:
                print(f"❌ 错误: 多边形 {i} 环 {j} 坐标太少")
                return False

            if ring[0] != ring[-1]:
                print(f"❌ 错误: 多边形 {i} 环 {j} 未闭合")
                return False

            # 验证每个坐标
            for k, coord in enumerate(ring):
                if not isinstance(coord, list) or len(coord) != 2:
                    print(f"❌ 错误: 多边形 {i} 环 {j} 坐标 {k} 格式错误")
                    return False

                lon, lat = coord
                # 验证经纬度范围
                if not (-180 <= lon <= 180):
                    print(f"❌ 错误: 经度 {lon} 超出范围 (-180 到 180)")
                    return False
                if not (-90 <= lat <= 90):
                    print(f"❌ 错误: 纬度 {lat} 超出范围 (-90 到 90)")
                    return False

    print("✅ 所有坐标验证通过")
    return True

def check_file_size(file_path):
    """检查文件大小"""
    size = os.path.getsize(file_path)
    size_kb = size / 1024
    print(f"📄 文件大小: {size_kb:.2f} KB")

    if size_kb > 1024:  # 1MB
        print("⚠️  警告: 文件较大，建议压缩")
        return False

    return True

def main():
    """主函数"""
    if len(sys.argv) != 2:
        print("使用方法: python validate_geojson.py <geojson文件>")
        sys.exit(1)

    file_path = sys.argv[1]

    if not os.path.exists(file_path):
        print(f"❌ 文件不存在: {file_path}")
        sys.exit(1)

    # 验证文件
    check_file_size(file_path)

    if validate_geojson(file_path):
        print("\n🎉 验证通过！文件符合 App Store Connect 要求")
        print("\n建议:")
        print("1. 如果使用全球范围，直接上传此文件")
        print("2. 如果有限制地区，确保坐标正确")
        print("3. 上传前在 App Store Connect 预览")
        sys.exit(0)
    else:
        print("\n❌ 验证失败！请修复上述问题")
        sys.exit(1)

if __name__ == "__main__":
    main()