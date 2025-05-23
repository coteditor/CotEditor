//
//  MovieAttributes.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-05-01.
//
//  ---------------------------------------------------------------------------
//
//  © 2025 1024jp
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import AVFoundation

struct MovieAttributes: FileContentAttributes {
    
    var dimensions: CGSize
    var duration: Duration
}


extension AVAsset {
    
    final var movieAttributes: MovieAttributes {
        
        get async throws {
            guard let track = try await self.loadTracks(withMediaType: .video).first else {
                throw AVError(.noSourceTrack)
            }
            
            return try await MovieAttributes(
                dimensions: track.size,
                duration: .seconds(self.load(.duration).seconds)
            )
        }
    }
}


private extension AVAssetTrack {
    
    /// The video dimensions in `CGSize`.
    ///
    /// - Note: The size can be `zero` if the receiver is non-visual track.
    var size: CGSize {
        
        get async throws {
            let (naturalSize, transform) = try await self.load(.naturalSize, .preferredTransform)
            let size = naturalSize.applying(transform)
            
            return CGSize(width: abs(size.width), height: abs(size.height))
        }
    }
}
