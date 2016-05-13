//******************************************************************************
//
// Copyright (c) 2015 Microsoft Corporation. All rights reserved.
//
// This code is licensed under the MIT License (MIT).
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//******************************************************************************

#pragma once

namespace winsdkfb 
{
    public ref class FBMediaStream sealed
    {
    public:
        FBMediaStream(
            Platform::String^ FileName,
            Windows::Storage::Streams::IRandomAccessStreamWithContentType^ Stream
            );

        property Windows::Storage::Streams::IRandomAccessStreamWithContentType^ Stream
        {
            Windows::Storage::Streams::IRandomAccessStreamWithContentType^ get();
        }

        property Platform::String^ FileName 
        { 
            Platform::String^ get(); 
        }

    private:
        Windows::Storage::Streams::IRandomAccessStreamWithContentType^ _stream;
        Platform::String^ _fileName;
    };
};
