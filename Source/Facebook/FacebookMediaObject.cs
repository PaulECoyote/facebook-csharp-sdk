﻿// --------------------------------
// <copyright file="FacebookMediaObject.cs" company="Thuzi, LLC">
//     Copyright (c) 2010 Thuzi, LLC (thuzi.com)
// </copyright>
// <author>Nathan Totten (ntotten.com) and Jim Zimmerman (jimzimmerman.com)</author>
// <license>Released under the terms of the Microsoft Public License (Ms-PL)</license>
// <website>http://facebooksdk.codeplex.com</website>
// ---------------------------------

namespace Facebook
{
    /// <summary>
    /// Represents a media object such as a photo or video.
    /// </summary>
    public class FacebookMediaObject
    {
        /// <summary>
        /// The value of the media object.
        /// </summary>
        private byte[] value;

        /// <summary>
        /// Gets or sets the type of the content.
        /// </summary>
        /// <value>The type of the content.</value>
        public string ContentType { get; set; }

        /// <summary>
        /// Gets or sets the name of the file.
        /// </summary>
        /// <value>The name of the file.</value>
        public string FileName { get; set; }

        /// <summary>
        /// Sets the value of the media object.
        /// </summary>
        /// <param name="value">The media object value.</param>
        public void SetValue(byte[] value)
        {
            this.value = value;
        }

        /// <summary>
        /// Gets the value of the media object.
        /// </summary>
        /// <returns>The value of the media object.</returns>
        public byte[] GetValue()
        {
            return this.value;
        }
    }
}